// ignore_for_file: deprecated_member_use

import 'package:cronograma/presentation/pages/Unidades%20Curriculares/unidades_curriculares_form.dart';
import 'package:cronograma/presentation/pages/Cronograma/cronograma_page.dart';
import 'package:cronograma/presentation/pages/turma/turma_page.dart';
import 'package:flutter/material.dart';
import 'package:cronograma/presentation/pages/cursos/curso_page_form.dart';
import 'package:cronograma/presentation/pages/instrutores/instrutor_page_form.dart';

class MainHomePage extends StatelessWidget {
  const MainHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Define a largura máxima para o conteúdo
          const maxContentWidth = 800.0;
          // Usa a menor entre a largura da tela e 800 pixels
          final contentWidth = constraints.maxWidth < maxContentWidth 
              ? constraints.maxWidth 
              : maxContentWidth;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0F7FA), // Cor mais clara do teal
                  Colors.white,
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo e título
                        const Column(
                          children: [
                            Icon(
                              Icons.school,
                              size: 60,
                              color: Colors.teal,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'SENAC Catalão',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            Text(
                              'Gestão de Cronogramas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Mensagem de boas-vindas
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Bem-vindo ao sistema de gestão de cronogramas',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Grid de botões - ajusta o número de colunas baseado no tamanho da tela
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Define o número de colunas baseado na largura disponível
                            int crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
                            
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 1.0,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              children: [
                                _buildMenuButton(
                                  context,
                                  icon: Icons.school,
                                  label: 'Cursos',
                                  color: Colors.teal,
                                  destination: const CursoPageForm(),
                                ),
                                _buildMenuButton(
                                  context,
                                  icon: Icons.person,
                                  label: 'Instrutores',
                                  color: Colors.blue,
                                  destination: const CadastroInstrutorPage(),
                                ),
                                _buildMenuButton(
                                  context,
                                  icon: Icons.book,
                                  label: 'Unidades Curriculares',
                                  color: Colors.purple,
                                  destination: const CadastroUnidadesCurricularesPage(),
                                ),
                                _buildMenuButton(
                                  context,
                                  icon: Icons.people_alt,
                                  label: 'Turma',
                                  color: const Color.fromARGB(255, 255, 0, 119),
                                  destination: const TurmaPageForm(),
                                ),
                                _buildMenuButton(
                                  context,
                                  icon: Icons.calendar_today,
                                  label: 'Cronograma',
                                  color: Colors.orange,
                                  destination: const CronogramaPage(),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Widget destination,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _navigateTo(context, destination),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }
}