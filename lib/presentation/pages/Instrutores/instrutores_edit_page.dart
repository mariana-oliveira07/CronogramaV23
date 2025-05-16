import 'package:cronograma/data/models/instrutores_model.dart';
import 'package:cronograma/data/repositories/instrutor_repository.dart';
import 'package:cronograma/presentation/viewmodels/estagio_viewmodels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    String formatted = '';

    if (text.isNotEmpty) {
      if (text.length <= 2) {
        formatted = '($text';
      } else if (text.length <= 3) {
        formatted = '(${text.substring(0, 2)}) ${text.substring(2)}';
      } else if (text.length <= 7) {
        formatted = '(${text.substring(0, 2)}) ${text.substring(2, 3)} ${text.substring(3)}';
      } else if (text.length <= 11) {
        formatted = '(${text.substring(0, 2)}) ${text.substring(2, 3)} ${text.substring(3, 7)} ${text.substring(7)}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EditInstrutorPage extends StatefulWidget {
  final Instrutores instrutor;

  const EditInstrutorPage({super.key, required this.instrutor});

  @override
  State<EditInstrutorPage> createState() => _EditInstrutorPageState();
}

class _EditInstrutorPageState extends State<EditInstrutorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _especializacaoController;
  final InstrutoresViewModel _viewModel = InstrutoresViewModel(InstrutoresRepository());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.instrutor.nomeInstrutor);
    _emailController = TextEditingController(text: widget.instrutor.email ?? '');
    _telefoneController = TextEditingController(text: _formatarTelefoneInicial(widget.instrutor.telefone ?? ''));
    _especializacaoController = TextEditingController(text: widget.instrutor.especializacao ?? '');
  }

  String _formatarTelefoneInicial(String telefone) {
    final digits = telefone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 3)} ${digits.substring(3, 7)} ${digits.substring(7)}';
    }
    return telefone;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _especializacaoController.dispose();
    super.dispose();
  }

  Future<void> _updateInstrutor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final instrutorAtualizado = Instrutores(
        idInstrutor: widget.instrutor.idInstrutor,
        nomeInstrutor: _nomeController.text,
        email: _emailController.text,
        telefone: _telefoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        especializacao: _especializacaoController.text,
      );

      await _viewModel.updateInstrutor(instrutorAtualizado);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instrutor atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar instrutor: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Instrutor'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateInstrutor,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Editar Instrutor',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nomeController,
                        decoration: InputDecoration(
                          labelText: 'Nome Completo',
                          prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o nome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _telefoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TelefoneInputFormatter(),
                          LengthLimitingTextInputFormatter(16),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Telefone Celular',
                          hintText: '(99) 9 9999 9999',
                          prefixIcon: Icon(Icons.phone, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _especializacaoController,
                        decoration: InputDecoration(
                          labelText: 'Especialização',
                          prefixIcon: Icon(Icons.school, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateInstrutor,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Salvar Alterações',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}