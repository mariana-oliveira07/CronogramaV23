import 'package:cronograma/data/models/cursos_model.dart';
import 'package:cronograma/data/repositories/cursos_repository.dart';
import 'package:cronograma/presentation/pages/cursos/curso_edit_page.dart'
    show EditCursoPage;
import 'package:cronograma/presentation/viewmodels/cursos_viewmodels.dart';
import 'package:flutter/material.dart';

class CursoPageForm extends StatefulWidget {
  const CursoPageForm({super.key});

  @override
  State<CursoPageForm> createState() => _CursoPageFormState();
}

class _CursoPageFormState extends State<CursoPageForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cargaHorariaController = TextEditingController();
  final CursosViewModel _viewModel = CursosViewModel(CursosRepository());
  bool _isLoading = false;
  List<Cursos> _cursos = [];
  int? _cursoParaExcluir;
  bool _mostrarConfirmacaoExclusao = false;

  @override
  void initState() {
    super.initState();
    _carregarCursos();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cargaHorariaController.dispose();
    super.dispose();
  }

  Future<void> _carregarCursos() async {
    setState(() => _isLoading = true);
    try {
      final cursos = await _viewModel.getCursos();
      setState(() => _cursos = cursos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar cursos: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCursos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final curso = Cursos(
        nomeCurso: _nomeController.text.trim(),
        cargahoraria: int.parse(_cargaHorariaController.text),
      );

      await _viewModel.addCurso(curso);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Curso adicionado com sucesso!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      // Limpa o formulário e recarrega a lista
      _formKey.currentState!.reset();
      _nomeController.clear();
      _cargaHorariaController.clear();
      await _carregarCursos();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar curso: ${e.toString()}'),
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

  Future<void> _editarCurso(Cursos curso) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditCursoPage(curso: curso),
      ),
    );

    if (result == true && mounted) {
      await _carregarCursos();
    }
  }

  Future<void> _confirmarExclusao(int cursoId) async {
    setState(() {
      _cursoParaExcluir = cursoId;
      _mostrarConfirmacaoExclusao = true;
    });

    // Aguarda 5 segundos
    await Future.delayed(const Duration(seconds: 5));

    // Se ainda estiver mostrando a confirmação e não foi cancelado, executa a exclusão
    if (mounted &&
        _mostrarConfirmacaoExclusao &&
        _cursoParaExcluir == cursoId) {
      await _excluirCurso(
          cursoId); // Adiciona esta linha para executar a exclusão
    }
  }

  Future<void> _cancelarExclusao() async {
    setState(() {
      _mostrarConfirmacaoExclusao = false;
      _cursoParaExcluir = null;
    });
  }

  Future<void> _excluirCurso(int cursoId) async {
    try {
      await _viewModel.deleteCurso(cursoId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Curso excluído com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      await _carregarCursos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir curso: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _mostrarConfirmacaoExclusao = false;
          _cursoParaExcluir = null;
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
        title: const Text('Cadastro de Cursos'),
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
                            'Cadastrar Novo Curso',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nomeController,
                            decoration: InputDecoration(
                              labelText: 'Nome do Curso',
                              prefixIcon: Icon(Icons.school,
                                  color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, informe o nome do curso';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _cargaHorariaController,
                            decoration: InputDecoration(
                              labelText: 'Carga Horária (horas)',
                              prefixIcon:
                                  Icon(Icons.timer, color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, informe a carga horária';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Informe um número válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveCursos,
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
                                          'Salvar Curso',
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
                  'Cursos Cadastrados',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : _cursos.isEmpty
                        ? const Text('Nenhum curso cadastrado')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _cursos.length,
                            itemBuilder: (context, index) {
                              final curso = _cursos[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(curso.nomeCurso),
                                  subtitle: Text(
                                      'Carga horária: ${curso.cargahoraria} horas'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: colorScheme.primary),
                                        onPressed: () => _editarCurso(curso),
                                      ),
                                      if (_mostrarConfirmacaoExclusao &&
                                          _cursoParaExcluir == curso.idCurso)
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
                                              curso.idCurso!),
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
