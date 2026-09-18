import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  int _score = 0;
  late List<int> _cards;
  late List<bool> _revealed;
  int? _firstSelected;
  int? _secondSelected;
  int _matches = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _cards = [1, 1, 2, 2, 3, 3, 4, 4];
    _cards.shuffle();
    _revealed = List.filled(8, false);
    _firstSelected = null;
    _secondSelected = null;
    _matches = 0;
    _score = 0;
  }

  void _cardTapped(int index) {
    if (_revealed[index]) return;

    setState(() {
      if (_firstSelected == null) {
        _firstSelected = index;
        _revealed[index] = true;
      } else if (_secondSelected == null) {
        _secondSelected = index;
        _revealed[index] = true;

        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          if (_cards[_firstSelected!] == _cards[_secondSelected!]) {
            _matches++;
            _score += 10;
            if (_matches == 4) {
              _showWinDialog();
            }
          } else {
            _revealed[_firstSelected!] = false;
            _revealed[_secondSelected!] = false;
          }
          _firstSelected = null;
          _secondSelected = null;
          setState(() {});
        });
      }
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¡Ganaste!'),
        content: Text('Puntuación: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context, true);
            },
            child: const Text('Finalizar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _initializeGame());
            },
            child: Text('Jugar Nuevamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        title: Text(
          '🎮 Juegos',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Puntuación
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Puntuación: $_score | Parejas: $_matches/4',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            // Grid de tarjetas
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: List.generate(8, (index) {
                  return GestureDetector(
                    onTap: () => _cardTapped(index),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _revealed[index]
                            ? const LinearGradient(
                                colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                              )
                            : LinearGradient(
                                colors: [colorScheme.surfaceContainerLow, colorScheme.outlineVariant],
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: _revealed[index]
                            ? Text(
                                '${_cards[index]}',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.question_mark,
                                color: colorScheme.onSurfaceVariant,
                                size: 32,
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => setState(() => _initializeGame()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Reiniciar',
                style: TextStyle(fontSize: 16.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
