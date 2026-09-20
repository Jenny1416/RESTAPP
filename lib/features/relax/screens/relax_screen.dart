import 'package:flutter/material.dart';
import 'games_screen.dart';
import 'jokes_screen.dart';
import 'music_screen.dart';
import 'physical_activity_screen.dart';
import 'yoga_screen.dart';

class RelaxScreen extends StatelessWidget {
  const RelaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón de cerrar
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.close,
                    size: width * 0.08,
                    color: Colors.blue,
                  ),
                ),
              ),
              SizedBox(height: height * 0.01),

              // Título
              Center(
                child: Text(
                  "Mis Técnicas de\nRelajación",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width * 0.07,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              SizedBox(height: height * 0.02),

              // Subtítulo con estrellita
              Row(
                children: [
                  Text("⭐ ", style: TextStyle(fontSize: width * 0.06)),
                  Expanded(
                    child: Text(
                      "Lo importante es mantener la calma y hacer algo que disfrutes",
                      style: TextStyle(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.03),

              // Caja con técnicas
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: width * 0.04,
                    mainAxisSpacing: height * 0.02,
                    children: const [
                      _CardTecnica(
                        imagen: "assets/images/yoga.png",
                        titulo: "Yoga",
                      ),
                      _CardTecnica(
                        imagen: "assets/images/chistes.png",
                        titulo: "Chistes",
                      ),
                      _CardTecnica(
                        imagen: "assets/images/Play.png",
                        titulo: "Juegos",
                      ),
                      _CardTecnica(
                        imagen: "assets/images/musica.png",
                        titulo: "Escuchar\nMusica",
                      ),
                      _CardTecnica(
                        imagen: "assets/images/gym.png",
                        titulo: "Actividad\nFísica",
                      ),
                    ],
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

class _CardTecnica extends StatelessWidget {
  final String imagen;
  final String titulo;

  const _CardTecnica({required this.imagen, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    Widget destination() {
      if (titulo == 'Yoga') return const YogaScreen();
      if (titulo == 'Chistes') return const JokesScreen();
      if (titulo == 'Juegos') return const GamesScreen();
      if (titulo.contains('Musica')) return const MusicScreen();
      return const PhysicalActivityScreen();
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination()),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
        color: Colors.lightBlue.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagen,
            width: width * 0.25,
            height: width * 0.25,
            fit: BoxFit.contain,
          ),
          SizedBox(height: width * 0.02),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: width * 0.045,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
        ),
      ),
    );
  }
}
