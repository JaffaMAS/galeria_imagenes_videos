// Servicio para cargar y listar medios usando `photo_manager`.
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaService {
  // Singleton
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  // Cache básico de álbumes para evitar recargas innecesarias
  List<AssetPathEntity>? _cachedAlbums;

  /// Obtiene la lista de álbumes. Usa cache simple en memoria.
  Future<List<AssetPathEntity>> getAlbums() async {
    if (_cachedAlbums != null) {
      debugPrint(
          '[MediaService] Usando álbumes cacheados (${_cachedAlbums!.length})');
      return _cachedAlbums!;
    }

    try {
      debugPrint('[MediaService] Solicitando lista de álbumes...');
      final List<AssetPathEntity> paths =
          await PhotoManager.getAssetPathList(onlyAll: false);

      _cachedAlbums = paths;
      debugPrint('[MediaService] Álbumes cargados: ${paths.length}');
      return paths;
    } catch (e, st) {
      debugPrint('[MediaService] Error al obtener álbumes: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// Carga assets paginados del álbum "Recent" (si existe) o del primer álbum disponible.
  /// Implementa paginación con `page` y `pageSize`.
  Future<List<AssetEntity>> loadMedia({int page = 0, int pageSize = 50}) async {
    try {
      final albums = await getAlbums();

      if (albums.isEmpty) {
        debugPrint('[MediaService] No se encontraron álbumes');
        return <AssetEntity>[];
      }

      // Buscar un álbum llamado "Recent" (insensible a mayúsculas). Si no, usar primer álbum.
      AssetPathEntity chosen = albums.first;
      try {
        chosen = albums.firstWhere((a) {
          final name = a.name.toLowerCase();
          return name.contains('recent') ||
              name.contains('recientes') ||
              a.isAll;
        });
      } catch (_) {
        chosen = albums.first;
      }

      debugPrint(
          '[MediaService] Cargando página $page (size: $pageSize) del álbum: ${chosen.name}');

      final List<AssetEntity> list =
          await chosen.getAssetListPaged(page: page, size: pageSize);

      debugPrint('[MediaService] Items obtenidos: ${list.length}');
      return list;
    } catch (e, st) {
      debugPrint('[MediaService] Error loadMedia: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// Limpia cache de álbumes si es necesario (útil en cambios de permisos)
  void clearCache() {
    _cachedAlbums = null;
    debugPrint('[MediaService] Cache de álbumes limpiada');
  }
}
