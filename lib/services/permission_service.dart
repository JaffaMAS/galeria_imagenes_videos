import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class PermissionService {
  // Singleton pattern
  PermissionService._privateConstructor();
  static final PermissionService _instance =
      PermissionService._privateConstructor();
  factory PermissionService() => _instance;

  /// Solicita los permisos necesarios para acceder a la galería de imágenes y videos.
  /// Retorna true si los permisos son otorgados, false en caso contrario.
  Future<bool> requestPermissions() async {
    try {
      // Verificar y solicitar permiso principal para medios (Android 13+)
      var photosStatus = await Permission.photos.status;
      if (!photosStatus.isGranted) {
        photosStatus = await Permission.photos.request();
      }

      if (!photosStatus.isGranted) {
        return false;
      }

      // Solicitar permisos extendidos de photo_manager (maneja Scoped Storage)
      try {
        final PermissionState ps = await PhotoManager.requestPermissionExtend();
        return ps.isAuth; // true si autorizado
      } catch (e) {
        debugPrint('PhotoManager.requestPermissionExtend error: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error al solicitar permisos: $e');
      return false;
    }
  }

  /// Muestra un diálogo informando al usuario que los permisos son necesarios.
  /// Ofrece la opción de abrir la configuración de la app.
  void handlePermissionDenied(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permisos requeridos'),
          content: const Text(
            'Esta aplicación necesita acceso a la galería de imágenes y videos para funcionar correctamente. '
            'Por favor, otorga los permisos necesarios en la configuración.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Abrir Configuración'),
            ),
          ],
        );
      },
    );
  }
}
