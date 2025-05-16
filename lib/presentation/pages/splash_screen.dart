import 'package:cronograma/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configuração das animações
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _scaleAnimation = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Tempo total da animação + delay (3 segundos)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[700],
      body: Stack(
        children: [
          // Fundo animado com ondas
          Positioned.fill(
            child: CustomPaint(
              painter: _WavePainter(),
            ),
          ),

          // Conteúdo central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone com animação de escala
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: const Icon(
                    Icons.schedule,
                    size: 100,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                // Título com fade-in
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'SENAC Cronogramas',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black45,
                          offset: Offset(2.0, 2.0),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Subtítulo
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Gestão de Cursos e Aulas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Indicador de progresso
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),

                const SizedBox(height: 20),

                // Versão do app
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Versão 1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pintor personalizado para efeito de ondas no fundo
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      // ignore: deprecated_member_use
      ..color = Colors.teal[900]!.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.6,
          size.width * 0.5, size.height * 0.7)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.8, size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}