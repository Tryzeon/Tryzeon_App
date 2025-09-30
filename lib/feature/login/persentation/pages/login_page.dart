import 'package:flutter/material.dart';
import 'store_login_page.dart';
import 'personal_login_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0E27),
              const Color(0xFF1A1F3A),
              const Color(0xFF2D1B4E),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo with glow effect
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F5FF).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 56,
                    color: const Color(0xFF00F5FF),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      const Color(0xFF00F5FF),
                      const Color(0xFF00D9FF),
                      const Color(0xFF00FFD1),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'TryZeon',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '虛擬穿搭 · 未來體驗',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF00F5FF).withValues(alpha: 0.8),
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),

                // 個人登入按鈕
                _FuturisticButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalLoginPage(),
                      ),
                    );
                  },
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00F5FF),
                      const Color(0xFF00C3FF),
                    ],
                  ),
                  icon: Icons.person_outline,
                  title: '個人登入',
                  subtitle: '探索虛擬試穿體驗',
                ),

                const SizedBox(height: 24),

                // 店家登入按鈕
                _FuturisticButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoreLoginPage(),
                      ),
                    );
                  },
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF00FF),
                      const Color(0xFFBD00FF),
                    ],
                  ),
                  icon: Icons.store_outlined,
                  title: '店家登入',
                  subtitle: '管理您的數位服飾',
                ),

                const Spacer(),

                // Footer
                Text(
                  'POWERED BY AI TECHNOLOGY',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FuturisticButton extends StatefulWidget {
  final VoidCallback onTap;
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;

  const _FuturisticButton({
    required this.onTap,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_FuturisticButton> createState() => _FuturisticButtonState();
}

class _FuturisticButtonState extends State<_FuturisticButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _isPressed ? 0.95 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: widget.gradient.colors.first,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}