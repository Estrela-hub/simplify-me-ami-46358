import 'package:flutter/material.dart';
import '../app_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;
  final VoidCallback? onBack; // Função para voltar ao ecrã Início

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
    this.onBack, // Opcional
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Se receber a função, usa-a. Se não, faz o padrão.
          onPressed: onBack ?? () => Navigator.pop(context), 
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey[500], height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}