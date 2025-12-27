import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/media_service.dart';
import '../widgets/thumbnail_widget.dart';

/// Pantalla principal de la galería que muestra un Grid de thumbnails.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<AssetEntity> _mediaList = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMoreMedia();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || !_hasMore) return;
    final threshold = 200.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
      _loadMoreMedia();
    }
  }

  Future<void> _loadMoreMedia() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      // Verificar permisos antes de intentar cargar
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth && !ps.hasAccess) {
        debugPrint(
            '[GalleryScreen] Permisos no otorgados al intentar cargar medios');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Permisos revocados. No se puede acceder a la galería.')),
          );
        }
        return;
      }

      final List<AssetEntity> newItems = await MediaService()
          .loadMedia(page: _currentPage, pageSize: _pageSize);

      if (!mounted) return;

      setState(() {
        _mediaList.addAll(newItems);
        _isLoading = false;
        _currentPage++;
        if (newItems.length < _pageSize) {
          _hasMore = false;
        }
      });

      // Si no hay álbumes o items en la primera carga
      if (_currentPage == 1 && _mediaList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron álbumes o medios.')),
        );
      }
    } catch (e, st) {
      debugPrint('[GalleryScreen] Error cargando medios: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar medios: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_mediaList.isEmpty && _isLoading) {
      // Cargando primera página
      return const Center(child: CircularProgressIndicator());
    }

    if (_mediaList.isEmpty && !_isLoading) {
      return const Center(child: Text('No hay medios'));
    }

    // Grid con posible indicador de carga al final
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: _mediaList.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _mediaList.length) {
          final asset = _mediaList[index];
          return ThumbnailWidget(
            asset: asset,
            onTap: () {
              debugPrint('[GalleryScreen] Tap en asset id=${asset.id}');
              // Módulo 3 implementará el visualizador completo
            },
          );
        }

        // Indicador pequeño al pie mientras se cargan más páginas
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
