import 'package:cronograma/presentation/pages/turma/turma_page.dart';
import 'package:flutter/material.dart';
import 'package:cronograma/presentation/pages/Instrutores/instrutor_page_form.dart';
import 'package:cronograma/presentation/pages/Unidades%20Curriculares/unidades_curriculares_form.dart';
import 'package:cronograma/presentation/pages/cursos/curso_page_form.dart';
import 'package:cronograma/presentation/pages/main_home_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const MainHomePage(),
    const CursoPageForm(),
    const CadastroInstrutorPage(),
    const CadastroUnidadesCurricularesPage(),
  ];

  // ignore: unused_element
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão dos Cronogramas'),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Ação para notificações
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal,
              Color(0xFFE0F2F1),
            ],
          ),
        ),
        child: _pages[_selectedIndex],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("Administrador"),
            accountEmail: Text("admin@senac.com.br"),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage('assets/profile_image.png'),
            ),
            decoration: BoxDecoration(
              color: Colors.teal,
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Página Inicial',
            destination: const MainHomePage(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.school,
            title: 'Cursos',
            destination: const CursoPageForm(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person,
            title: 'Instrutores',
            destination: const CadastroInstrutorPage(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.book,
            title: 'Unidades Curriculares',
            destination: const CadastroUnidadesCurricularesPage(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people_alt,
            title: 'Turmas',
            destination: const TurmaPageForm(),
          ),
          // const Divider(),
          // _buildDrawerItem(
          //   context,
          //   icon: Icons.settings,
          //   title: 'Configurações',
          //   destination: Container(), // Substitua pela página de configurações
          // ),
          // _buildDrawerItem(
          //   context,
          //   icon: Icons.exit_to_app,
          //   title: 'Sair',
          //   destination: Container(), // Lógica de logout
          // ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget destination,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Fecha o drawer
        if (destination is MainHomePage) {
          setState(() => _selectedIndex = 0);
        } else if (destination is CursoPageForm) {
          setState(() => _selectedIndex = 1);
        } else if (destination is CadastroInstrutorPage) {
          setState(() => _selectedIndex = 2);
        } else if (destination is CadastroUnidadesCurricularesPage) {
          setState(() => _selectedIndex = 3);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        }
      },
    );
  }
}
