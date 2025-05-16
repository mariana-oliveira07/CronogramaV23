import 'package:cronograma/data/models/cursos_model.dart';
import 'package:cronograma/data/models/unidades_curriculares_model.dart';
import 'package:cronograma/data/repositories/cursos_repository.dart';
import 'package:cronograma/data/repositories/unidades_curriculares_repository.dart';
import 'package:cronograma/presentation/pages/Unidades%20Curriculares/edit_unidades_curriculares.dart'
    show EditUnidadeCurricularPage;
import 'package:cronograma/presentation/viewmodels/cursos_viewmodels.dart';
import 'package:cronograma/presentation/viewmodels/unidades_curriculares_viewmodels.dart';
import 'package:flutter/material.dart';

class CadastroUnidadesCurricularesPage extends StatefulWidget {
  const CadastroUnidadesCurricularesPage({super.key});

  @override
  State<CadastroUnidadesCurricularesPage> createState() =>
      _CadastroUnidadesCurricularesPageState();
}

class _CadastroUnidadesCurricularesPageState
    extends State<CadastroUnidadesCurricularesPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cargaHorariaController = TextEditingController();
  final CursosViewModel _cursosViewModel = CursosViewModel(CursosRepository());
  final UnidadesCurricularesViewModel _viewModel =
      UnidadesCurricularesViewModel(UnidadesCurricularesRepository());
  bool _isLoading = false;
  List<Cursos> _cursos = [];
  Cursos? _cursoSelecionado;
  Cursos? _cursoFiltroSelecionado; // Novo campo para o filtro
  List<UnidadesCurriculares> _unidadesCurriculares = [];
  List<UnidadesCurriculares> _unidadesFiltradas = []; // Lista filtrada
  int? _ucParaExcluir;
  bool _mostrarConfirmacaoExclusao = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final listaCursos = await _cursosViewModel.getCursos();
      final listaUCs = await _viewModel.getUnidadesCurriculares();

      if (mounted) {
        setState(() {
          _cursos = listaCursos;
          _unidadesCurriculares = listaUCs;
          // Inicializa com o primeiro curso se disponível
          if (_cursos.isNotEmpty && _cursoSelecionado == null) {
            _cursoSelecionado = _cursos.first;
            _cursoFiltroSelecionado = _cursos.first;
          }
          _aplicarFiltro(); // Aplica o filtro após carregar os dados
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Método para aplicar o filtro
  void _aplicarFiltro() {
    if (_cursoFiltroSelecionado == null) {
      _unidadesFiltradas = List.from(_unidadesCurriculares);
    } else {
      _unidadesFiltradas = _unidadesCurriculares
          .where((uc) => uc.idcurso == _cursoFiltroSelecionado!.idCurso)
          .toList();
    }
  }

  Future<void> _saveUnidadeCurricular() async {
    if (!_formKey.currentState!.validate() || _cursoSelecionado == null) return;

    setState(() => _isLoading = true);

    try {
      final uc = UnidadesCurriculares(
        nomeUc: _nomeController.text,
        cargahoraria: int.parse(_cargaHorariaController.text),
        idcurso: _cursoSelecionado!.idCurso!, // Garantia de não nulo
      );

      await _viewModel.addUnidadeCurricular(uc);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidade salva com sucesso!')),
        );
        // Limpa o formulário
        _formKey.currentState!.reset();
        _nomeController.clear();
        _cargaHorariaController.clear();
        await _carregarDados(); // Recarrega a lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editarUnidadeCurricular(UnidadesCurriculares uc) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditUnidadeCurricularPage(
          unidadeCurricular: uc,
          cursos: _cursos,
        ),
      ),
    );

    if (result == true && mounted) {
      await _carregarDados();
    }
  }

  Future<void> _confirmarExclusao(int idUc) async {
    setState(() {
      _ucParaExcluir = idUc;
      _mostrarConfirmacaoExclusao = true;
    });

    await Future.delayed(const Duration(seconds: 5));

    if (mounted && _mostrarConfirmacaoExclusao && _ucParaExcluir == idUc) {
      await _excluirUnidadeCurricular(idUc);
    }
  }

  Future<void> _cancelarExclusao() async {
    setState(() {
      _mostrarConfirmacaoExclusao = false;
      _ucParaExcluir = null;
    });
  }

  Future<void> _excluirUnidadeCurricular(int idUc) async {
    try {
      await _viewModel.deleteUnidadeCurricular(idUc);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unidade Curricular excluída com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      await _carregarDados();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _mostrarConfirmacaoExclusao = false;
          _ucParaExcluir = null;
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
        title: const Text('Unidades Curriculares'),
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
                            'Cadastrar Nova Unidade Curricular',
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
                              prefixIcon: Icon(Icons.school,
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
                            controller: _cargaHorariaController,
                            decoration: InputDecoration(
                              labelText: 'Carga Horária',
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
                            items: _cursos.map((curso) {
                              return DropdownMenuItem<Cursos>(
                                value: curso,
                                child: Text(curso.nomeCurso),
                              );
                            }).toList(),
                            onChanged: (Cursos? novoValor) {
                              if (novoValor != null) {
                                setState(() {
                                  _cursoSelecionado = novoValor;
                                });
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Curso',
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(Icons.school,
                                  color: Theme.of(context).primaryColor),
                            ),
                            validator: (value) =>
                                value == null ? 'Selecione um curso' : null,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _saveUnidadeCurricular,
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
                                          'Salvar Unidade Curricular',
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
                  'Unidades Curriculares Cadastradas',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Adicionando o filtro de cursos
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt),
                        const SizedBox(width: 8),
                        const Text('Filtrar por curso:'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<Cursos>(
                            value: _cursoFiltroSelecionado,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<Cursos>(
                                value: null,
                                child: Text('Todos os cursos'),
                              ),
                              ..._cursos.map((curso) {
                                return DropdownMenuItem<Cursos>(
                                  value: curso,
                                  child: Text(curso.nomeCurso),
                                );
                              }),
                            ],
                            onChanged: (Cursos? novoValor) {
                              setState(() {
                                _cursoFiltroSelecionado = novoValor;
                                _aplicarFiltro();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _isLoading
                    ? const CircularProgressIndicator()
                    : _unidadesFiltradas.isEmpty
                        ? const Text('Nenhuma unidade curricular cadastrada')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _unidadesFiltradas.length,
                            itemBuilder: (context, index) {
                              final uc = _unidadesFiltradas[index];
                              final curso = _cursos.firstWhere(
                                (c) => c.idCurso == uc.idcurso,
                                orElse: () => const Cursos(
                                    nomeCurso: 'Curso não encontrado',
                                    cargahoraria: 0),
                              );
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(uc.nomeUc),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Carga horária: ${uc.cargahoraria} horas'),
                                      Text('Curso: ${curso.nomeCurso}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: colorScheme.primary),
                                        onPressed: () =>
                                            _editarUnidadeCurricular(uc),
                                      ),
                                      if (_mostrarConfirmacaoExclusao &&
                                          _ucParaExcluir == uc.idUc)
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
                                          onPressed: () =>
                                              _confirmarExclusao(uc.idUc!),
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
