import 'package:flutter/material.dart';
import 'dart:math';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class JokesScreen extends StatefulWidget {
  const JokesScreen({super.key});

  @override
  State<JokesScreen> createState() => _JokesScreenState();
}

class _JokesScreenState extends State<JokesScreen> {
  final Random _random = Random();
  int _currentJoke = 0;
  bool _showPunchline = false;

  final List<Map<String, String>> jokes = [
    {
      'setup': '¿Por qué los pájaros no se pierden cuando vuelan?',
      'punchline': '¡Porque usan el Mapache!',
    },
    {
      'setup': '¿Qué dijo el número 0 al número 8?',
      'punchline': '¡Qué bonito cinturón!',
    },
    {
      'setup': '¿Cuál es el colmo para un electricista?',
      'punchline': '¡Que su hijo sea un desconectado!',
    },
    {
      'setup': '¿Qué se siente tener los ojos azules en un país de gatos?',
      'punchline': '¡Que todos piensen que eres un peluche!',
    },
    {
      'setup': '¿Por qué las ovejas no se pierden en la nieve?',
      'punchline': '¡Porque tienen GPS: guía para ovejas pastadas!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentJoke = _random.nextInt(jokes.length);
  }

  void _showAnotherJoke() {
    if (jokes.length < 2) return;

    var next = _currentJoke;
    while (next == _currentJoke) {
      next = _random.nextInt(jokes.length);
    }

    setState(() {
      _currentJoke = next;
      _showPunchline = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores basados en HomeScreen
    final cardColor = isDark
        ? const Color(0xFF1E3A4A)
        : const Color(0xFF87CEEB);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : const Color(0xFF87CEEB).withValues(alpha: 0.4);
    final onCardColor = isDark ? const Color(0xFF90CAF9) : Colors.white;
    final secondaryTextColor = isDark
        ? const Color(0xFF64B5F6)
        : Colors.white70;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          '😂 Chistes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
            fontFamily: 'Fredoka',
            fontSize: 22.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(
            color: colorScheme.outlineVariant,
            thickness: 1,
            height: 1.h,
            indent: 20,
            endIndent: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 24.h),
              // Tarjeta del chiste
              GestureDetector(
                onTap: () => setState(() => _showPunchline = !_showPunchline),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        jokes[_currentJoke]['setup']!,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: onCardColor,
                          fontFamily: 'Fredoka',
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30.h),
                      if (_showPunchline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            jokes[_currentJoke]['punchline']!,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: onCardColor,
                              fontFamily: 'Fredoka',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Text(
                          'Toca para ver la respuesta ✨',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: secondaryTextColor,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Fredoka',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showAnotherJoke,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Otro chiste'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
