import 'package:cronograma/data/models/instrutores_model.dart';
import 'package:cronograma/data/repositories/instrutor_repository.dart';
import 'package:cronograma/presentation/pages/Instrutores/instrutores_edit_page.dart'
    show EditInstrutorPage;
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

class CadastroInstrutorPage extends StatefulWidget {
  const CadastroInstrutorPage({super.key});

  @override
  State<CadastroInstrutorPage> createState() => _CadastroInstrutorPageState();
}

class _CadastroInstrutorPageState extends State<CadastroInstrutorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _especializacaoController = TextEditingController();
  final InstrutoresViewModel _viewModel =
      InstrutoresViewModel(InstrutoresRepository());
  bool _isLoading = false;
  List<Instrutores> _instrutores = [];
  int? _instrutorParaExcluir;
  bool _mostrarConfirmacaoExclusao = false;

  @override
  void initState() {
    super.initState();
    _carregarInstrutores();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _especializacaoController.dispose();
    super.dispose();
  }

  String _formatarTelefoneExibicao(String telefone) {
    final digits = telefone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length >= 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 3)} ${digits.substring(3, 7)}-${digits.substring(7, 11)}';
    }
    return telefone;
  }

  Future<void> _carregarInstrutores() async {
    setState(() => _isLoading = true);
    try {
      final instrutores = await _viewModel.getInstrutores();
      setState(() => _instrutores = instrutores);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar instrutores: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveInstrutores() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final instrutor = Instrutores(
        nomeInstrutor: _nomeController.text,
        email: _emailController.text,
        telefone: _telefoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        especializacao: _especializacaoController.text,
      );

      await _viewModel.addInstrutor(instrutor);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instrutor adicionado com sucesso!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      _nomeController.clear();
      _emailController.clear();
      _telefoneController.clear();
      _especializacaoController.clear();
      await _carregarInstrutores();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar instrutor: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editarInstrutor(Instrutores instrutor) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditInstrutorPage(instrutor: instrutor),
      ),
    );

    if (result == true && mounted) {
      await _carregarInstrutores();
    }
  }

  Future<void> _confirmarExclusao(int instrutorId) async {
    setState(() {
      _instrutorParaExcluir = instrutorId;
      _mostrarConfirmacaoExclusao = true;
    });

    await Future.delayed(const Duration(seconds: 5));

    if (mounted &&
        _mostrarConfirmacaoExclusao &&
        _instrutorParaExcluir == instrutorId) {
      await _excluirInstrutor(instrutorId);
    }
  }

  Future<void> _cancelarExclusao() async {
    setState(() {
      _mostrarConfirmacaoExclusao = false;
      _instrutorParaExcluir = null;
    });
  }

  Future<void> _excluirInstrutor(int instrutorId) async {
    try {
      await _viewModel.deleteInstrutor(instrutorId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instrutor excluído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      await _carregarInstrutores();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir instrutor: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _mostrarConfirmacaoExclusao = false;
          _instrutorParaExcluir = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Instrutor'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Card(
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
                            'Cadastrar Novo Instrutor',
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
                              prefixIcon: Icon(Icons.person,
                                  color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
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
                              prefixIcon:
                                  Icon(Icons.email, color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
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
                              LengthLimitingTextInputFormatter(16), // (XX) X XXXX XXXX = 16 caracteres
                            ],
                            decoration: InputDecoration(
                              labelText: 'Telefone Celular',
                              hintText: '(99) 9 9999 9999', // Hint sem hífen
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
                              prefixIcon:
                                  Icon(Icons.school, color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveInstrutores,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                                          'Salvar Instrutor',
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
                const SizedBox(height: 32),
                Text(
                  'Instrutores Cadastrados',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : _instrutores.isEmpty
                        ? const Text('Nenhum instrutor cadastrado')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _instrutores.length,
                            itemBuilder: (context, index) {
                              final instrutor = _instrutores[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(instrutor.nomeInstrutor),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (instrutor.email != null &&
                                          instrutor.email!.isNotEmpty)
                                        Text('Email: ${instrutor.email}'),
                                      if (instrutor.telefone != null &&
                                          instrutor.telefone!.isNotEmpty)
                                        Text(
                                            'Telefone: ${_formatarTelefoneExibicao(instrutor.telefone!)}'),
                                      if (instrutor.especializacao != null &&
                                          instrutor.especializacao!.isNotEmpty)
                                        Text(
                                            'Especialização: ${instrutor.especializacao}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: colorScheme.primary),
                                        onPressed: () =>
                                            _editarInstrutor(instrutor),
                                      ),
                                      if (_mostrarConfirmacaoExclusao &&
                                          _instrutorParaExcluir ==
                                              instrutor.idInstrutor)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.red),
                                              onPressed: _cancelarExclusao,
                                            ),
                                            TweenAnimationBuilder(
                                              tween: IntTween(begin: 5, end: 0),
                                              duration:
                                                  const Duration(seconds: 5),
                                              builder: (context, value, child) {
                                                return Text('$value');
                                              },
                                            ),
                                          ],
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _confirmarExclusao(
                                              instrutor.idInstrutor!),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}