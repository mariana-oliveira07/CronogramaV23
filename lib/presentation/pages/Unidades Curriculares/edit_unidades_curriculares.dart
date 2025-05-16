import 'package:cronograma/data/models/cursos_model.dart';
import 'package:cronograma/data/models/unidades_curriculares_model.dart';
import 'package:cronograma/data/repositories/cursos_repository.dart';
import 'package:cronograma/data/repositories/unidades_curriculares_repository.dart';
import 'package:cronograma/presentation/viewmodels/cursos_viewmodels.dart';
import 'package:cronograma/presentation/viewmodels/unidades_curriculares_viewmodels.dart';
import 'package:flutter/material.dart';

class EditUnidadeCurricularPage extends StatefulWidget {
  final UnidadesCurriculares unidadeCurricular;
  final List<Cursos> cursos;

  const EditUnidadeCurricularPage({
    super.key,
    required this.unidadeCurricular,
    required this.cursos,
  });

  @override
  State<EditUnidadeCurricularPage> createState() =>
      _EditUnidadeCurricularPageState();
}

class _EditUnidadeCurricularPageState extends State<EditUnidadeCurricularPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _cargaHorariaController;
  final UnidadesCurricularesViewModel _viewModel =
      UnidadesCurricularesViewModel(UnidadesCurricularesRepository());
  // ignore: unused_field
  final CursosViewModel _cursosViewModel = CursosViewModel(CursosRepository());
  bool _isLoading = false;
  Cursos? _cursoSelecionado;

  @override
  void initState() {
    super.initState();
    _nomeController =
        TextEditingController(text: widget.unidadeCurricular.nomeUc);
    _cargaHorariaController = TextEditingController(
        text: widget.unidadeCurricular.cargahoraria.toString());
    _cursoSelecionado = widget.cursos.firstWhere(
      (curso) => curso.idCurso == widget.unidadeCurricular.idcurso,
      orElse: () => widget.cursos.first,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cargaHorariaController.dispose();
    super.dispose();
  }

  Future<void> _updateUnidadeCurricular() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final unidadeAtualizada = UnidadesCurriculares(
        idUc: widget.unidadeCurricular.idUc,
        nomeUc: _nomeController.text,
        cargahoraria: int.parse(_cargaHorariaController.text),
        idcurso: _cursoSelecionado!.idCurso!,
      );

      await _viewModel.updateUnidadeCurricular(unidadeAtualizada);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unidade Curricular atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar: ${e.toString()}'),
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
        title: const Text('Editar Unidade Curricular'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateUnidadeCurricular,
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
                        'Editar Unidade Curricular',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nomeController,
                        decoration: InputDecoration(
                          labelText: 'Nome',
                          prefixIcon:
                              Icon(Icons.school, color: colorScheme.primary),
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
                        controller: _cargaHorariaController,
                        decoration: InputDecoration(
                          labelText: 'Carga Horária',
                          prefixIcon:
                              Icon(Icons.timer, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a carga horária';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Informe um número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<Cursos>(
                        value: _cursoSelecionado,
                        items: widget.cursos.map((curso) {
                          return DropdownMenuItem<Cursos>(
                            value: curso,
                            child: Text(curso.nomeCurso),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _cursoSelecionado = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Curso',
                          prefixIcon:
                              Icon(Icons.menu_book, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor, selecione um curso';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _updateUnidadeCurricular,
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
