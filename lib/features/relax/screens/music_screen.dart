import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  bool _isPlaying = false;
  int _selectedPlaylist = 0;

  final List<Map<String, String>> playlists = [
    {'name': 'Relajación', 'songs': '12 canciones'},
    {'name': 'Meditación', 'songs': '8 canciones'},
    {'name': 'Zen', 'songs': '15 canciones'},
    {'name': 'Musicoterapia', 'songs': '10 canciones'},
  ];

  final List<String> songs = [
    'Serenidad en el Bosque',
    'Lluvia Suave',
    'Océano Tranquilo',
    'Atardecer Rosa',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    final cardColor = appColors.brandSoft;
    final shadowColor = appColors.brandSoft.withValues(alpha: 0.4);
    final onCardColor = appColors.overlayOnGradient;
    final secondaryTextColor = appColors.overlayOnGradient.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          '🎵 Música',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              // Reproductor
              Container(
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
                      'Ahora reproduciendo:',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14.sp,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                    SizedBox(height: 16.h),
                    GestureDetector(
                      onTap: () => setState(() => _isPlaying = !_isPlaying),
                      child: Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: appColors.overlayOnGradient.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: appColors.overlayOnGradient,
                          size: 40,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      songs[0],
                      style: TextStyle(
                        color: onCardColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Fredoka',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              // Playlists
              Text(
                'Mis Playlists:',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Fredoka',
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(height: 16.h),
              ...List.generate(
                playlists.length,
                (index) => GestureDetector(
                  onTap: () => setState(() => _selectedPlaylist = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _selectedPlaylist == index
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerLow,
                      border: Border.all(
                        color: _selectedPlaylist == index
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.playlist_play,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlists[index]['name']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                  fontFamily: 'Fredoka',
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                playlists[index]['songs']!,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 14.sp,
                                  fontFamily: 'Fredoka',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              // Canciones
              Text(
                'Canciones en ${playlists[_selectedPlaylist]['name']}:',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Fredoka',
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(height: 16.h),
              ...List.generate(
                songs.length,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          songs[index],
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontFamily: 'Fredoka',
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.play_circle_filled_rounded,
                        color: colorScheme.primary,
                        size: 24,
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

