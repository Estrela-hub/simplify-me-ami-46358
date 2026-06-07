import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../services/interaction_logger.dart';
import '../services/audio_service.dart';
import 'calendar/calendar_screen.dart';
import 'routine/routine_screen.dart';
import 'timer/timer_screen.dart';
import 'notes/notes_screen.dart';
import 'placeholder_screen.dart';
import 'test_control_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _subRoute;

  @override
  void dispose() {
    AudioService.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    InteractionLogger.log('Navegação', 'TAB_MUDANCA',
        details: 'Para: ${_tabTitles[index]}');
    setState(() {
      _currentIndex = index;
      _subRoute = null;
    });
  }

  void _goHome() {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = 0);
  }

  void _openSubRoute(String route) {
    HapticFeedback.lightImpact();
    setState(() => _subRoute = route);
  }

  void _closeSubRoute() {
    HapticFeedback.selectionClick();
    setState(() => _subRoute = null);
  }

  static const _tabTitles = ['Início', 'Calendário', 'Rotina', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildCurrentScreen(),
          const TestControlOverlay(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: const Color(0xFF528265),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Calendário'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Rotina'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    if (_subRoute != null) {
      switch (_subRoute) {
        case 'notes':
          return NotesScreen(onBack: _closeSubRoute);
        case 'timer':
          return TimerScreen(onBack: _closeSubRoute);
        case 'agua':
          return PlaceholderScreen(title: 'Água', icon: Icons.water_drop_outlined, message: 'Registo de consumo de água\nem desenvolvimento.', onBack: _closeSubRoute);
        case 'caminhadas':
          return PlaceholderScreen(title: 'Caminhadas', icon: Icons.directions_walk_outlined, message: 'Registo de caminhadas\nem desenvolvimento.', onBack: _closeSubRoute);
        case 'notificacoes':
          return PlaceholderScreen(title: 'Notificações', icon: Icons.notifications_outlined, message: 'Centro de notificações\nem desenvolvimento.', onBack: _closeSubRoute);
        case 'disposicao':
          return PlaceholderScreen(title: 'Disposição', icon: Icons.sentiment_satisfied_outlined, message: 'Registo de disposição\nem desenvolvimento.', onBack: _closeSubRoute);
      }
    }

    switch (_currentIndex) {
      case 0:
        return _InicioScreen(onSubRouteTap: _openSubRoute);
      case 1:
        return const CalendarScreen();
      case 2:
        return const RoutineScreen();
      case 3:
        // O Perfil também usa o PlaceholderScreen com a seta para voltar ao Início
        return PlaceholderScreen(title: 'Perfil', icon: Icons.person_outline, message: 'Funcionalidade em desenvolvimento.', onBack: _goHome);
      default:
        return _InicioScreen(onSubRouteTap: _openSubRoute);
    }
  }
}

/// Ecrã Início com saudação, círculos decorativos e 6 cartões de funcionalidades.
class _InicioScreen extends StatelessWidget {
  final ValueChanged<String> onSubRouteTap;

  static const decorationColor = Color.fromRGBO(141, 232, 150, 0.56);

  const _InicioScreen({required this.onSubRouteTap});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bom dia!' : hour < 20 ? 'Boa tarde!' : 'Boa noite!';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned(top: -75, left: -75, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(top: -65, left: 20, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(bottom: -75, right: -75, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(bottom: -65, right: 20, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  GestureDetector(
                    onLongPress: () => _showLogDialog(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SimplifyMe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0))),
                        const SizedBox(height: 4),
                        Text(greeting, style: const TextStyle(fontSize: 20, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 40,
                        crossAxisSpacing: 40,
                        childAspectRatio: 1.00,
                        children: [
                          _FeatureCard(icon: Icons.timer_outlined, title: 'Temporizador', color: const Color(0xFF6C63FF), onTap: () => onSubRouteTap('timer')),
                          _FeatureCard(icon: Icons.note_outlined, title: 'Notas', color: const Color(0xFFFF6B6B), onTap: () => onSubRouteTap('notes')),
                          _FeatureCard(icon: Icons.water_drop_outlined, title: 'Água', color: const Color(0xFF4ECDC4), onTap: () => onSubRouteTap('agua')),
                          _FeatureCard(icon: Icons.directions_walk_outlined, title: 'Caminhadas', color: const Color(0xFFFFB347), onTap: () => onSubRouteTap('caminhadas')),
                          _FeatureCard(icon: Icons.notifications_outlined, title: 'Notificações', color: const Color(0xFF45B7D1), onTap: () => onSubRouteTap('notificacoes')),
                          _FeatureCard(icon: Icons.sentiment_satisfied_outlined, title: 'Disposição', color: const Color(0xFF96CEB4), onTap: () => onSubRouteTap('disposicao')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogDialog(BuildContext context) {
    final logs = InteractionLogger.exportLogs();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logs de Interação (Debug)'),
        content: SizedBox(width: double.maxFinite, height: 400, child: SingleChildScrollView(child: SelectableText(logs, style: const TextStyle(fontSize: 9, fontFamily: 'monospace')))),
        actions: [
          TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: logs)); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs copiados!'))); }, child: const Text('Copiar')),
          TextButton(onPressed: () { InteractionLogger.clear(); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs limpos.'))); }, child: const Text('Limpar Logs')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { InteractionLogger.log('Início', 'CARTAO_TOQUE', details: title); onTap(); },
      child: Container(
        decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle), child: Icon(icon, size: 26, color: color)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}