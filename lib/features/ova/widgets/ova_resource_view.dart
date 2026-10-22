import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/utils/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/ova_models.dart';

/// Muestra el recurso de una actividad según su tipo: YouTube y MP4 dentro de
/// la app; imágenes inline; audio, PDF y enlaces se abren fuera de la app.
class OvaResourceView extends StatelessWidget {
  const OvaResourceView({super.key, required this.recurso});

  final OvaRecurso recurso;

  @override
  Widget build(BuildContext context) {
    if (!recurso.esUtilizable) return const _Unavailable();

    switch (recurso.media) {
      case OvaMedia.youtube:
        return _YoutubeView(videoId: recurso.videoId!);
      case OvaMedia.video:
        return _NetworkVideoView(recurso: recurso);
      case OvaMedia.imagen:
        return _ImageView(recurso: recurso);
      case OvaMedia.audio:
        return _OpenCard(
          icon: Icons.headphones_rounded,
          label: 'Escuchar audio',
          url: recurso.urlParaAbrir,
        );
      case OvaMedia.pdf:
        return _OpenCard(
          icon: Icons.picture_as_pdf_rounded,
          label: 'Abrir documento',
          url: recurso.urlParaAbrir,
        );
      case OvaMedia.enlace:
        return _OpenCard(
          icon: Icons.open_in_new_rounded,
          label: 'Abrir enlace',
          url: recurso.urlParaAbrir,
        );
    }
  }
}

Future<void> _openExternal(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  var opened = false;
  if (uri != null) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened && context.mounted) {
    AppToast.error(context, 'No pudimos abrir el recurso. Intenta de nuevo.');
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _Frame(
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.onSurfaceVariant),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Esta actividad no está disponible por ahora. Avísale a tu psicólogo para que la revise.',
              style: TextStyle(
                fontFamily: 'Fredoka',
                height: 1.35,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _OpenCard extends StatelessWidget {
  const _OpenCard({required this.icon, required this.label, required this.url});

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final colors = Theme.of(context).colorScheme;
    return _Frame(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: appColors.accentBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34.sp, color: appColors.accentBlue),
          ),
          SizedBox(height: 12.h),
          Text(
            'Se abrirá fuera de la app. Cuando termines, vuelve y marca la actividad como hecha.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 13.sp,
              height: 1.35,
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 14.h),
          FilledButton.icon(
            onPressed: () => _openExternal(context, url),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: appColors.accentBlue,
              foregroundColor: appColors.overlayOnGradient,
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 13.h),
              textStyle: const TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YoutubeView extends StatefulWidget {
  const _YoutubeView({required this.videoId});

  final String videoId;

  @override
  State<_YoutubeView> createState() => _YoutubeViewState();
}

class _YoutubeViewState extends State<_YoutubeView> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        interfaceLanguage: 'es',
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: YoutubePlayer(controller: _controller, aspectRatio: 16 / 9),
    );
  }
}

class _NetworkVideoView extends StatefulWidget {
  const _NetworkVideoView({required this.recurso});

  final OvaRecurso recurso;

  @override
  State<_NetworkVideoView> createState() => _NetworkVideoViewState();
}

class _NetworkVideoViewState extends State<_NetworkVideoView> {
  late final VideoPlayerController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.recurso.resolvedUrl),
    );
    _controller.addListener(_onChange);
    _controller
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        });
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _controller.value.hasError) {
      return _OpenCard(
        icon: Icons.play_circle_outline_rounded,
        label: 'Ver video',
        url: widget.recurso.resolvedUrl,
      );
    }
    if (!_controller.value.isInitialized) {
      return _Frame(
        child: SizedBox(
          height: 160.h,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final playing = _controller.value.isPlaying;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: GestureDetector(
                onTap: () => playing ? _controller.pause() : _controller.play(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    AnimatedOpacity(
                      opacity: playing ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 44.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: EdgeInsets.symmetric(vertical: 6.h),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageView extends StatelessWidget {
  const _ImageView({required this.recurso});

  final OvaRecurso recurso;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Image.network(
        recurso.resolvedUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : SizedBox(
                height: 160.h,
                child: const Center(child: CircularProgressIndicator()),
              ),
        errorBuilder: (context, error, stackTrace) => _OpenCard(
          icon: Icons.image_outlined,
          label: 'Ver imagen',
          url: recurso.resolvedUrl,
        ),
      ),
    );
  }
}
