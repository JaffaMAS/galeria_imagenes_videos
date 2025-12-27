import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'services/permission_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galería de Imágenes y Videos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PermissionTestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PermissionTestScreen extends StatefulWidget {
  const PermissionTestScreen({super.key});

  @override
  State<PermissionTestScreen> createState() => _PermissionTestScreenState();
}

class _PermissionTestScreenState extends State<PermissionTestScreen>
    with WidgetsBindingObserver {
  bool _permissionsGranted = false;
  bool _isLoading = true;
  bool _isCheckingPermissions = false;
  bool _hasShownDialog = false;
  bool _isDialogOpen = false; // ← NUEVO: Controla si el diálogo está abierto
  String _statusMessage = 'Verificando permisos...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Solo re-chequear si no estamos ya verificando y si habíamos mostrado el diálogo
      if (!_isCheckingPermissions && _hasShownDialog) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            debugPrint('App resumed, rechecking permissions...');
            _hasShownDialog = false;
            _checkPermissions();
          }
        });
      }
    }
  }

  Future<void> _checkPermissions() async {
    if (!mounted || _isCheckingPermissions) return;

    setState(() {
      _isCheckingPermissions = true;
      _isLoading = true;
      _statusMessage = 'Verificando permisos...';
    });

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();

      debugPrint('PhotoManager permission state: ${ps.name}');

      if (ps.isAuth || ps.hasAccess) {
        // ← NUEVO: Si hay permisos y el diálogo está abierto, cerrarlo
        if (_isDialogOpen && mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _isDialogOpen = false;
        }

        // Permisos otorgados
        if (!mounted) return;
        setState(() {
          _permissionsGranted = true;
          _isLoading = false;
          _isCheckingPermissions = false;
          _hasShownDialog = false;
          _statusMessage = '¡Permisos otorgados correctamente!';
        });

        // Mostrar SnackBar de confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Permisos otorgados - Listo para cargar galería'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Permisos denegados o limitados
        if (!mounted) return;
        setState(() {
          _permissionsGranted = false;
          _isLoading = false;
          _isCheckingPermissions = false;
          _statusMessage = ps == PermissionState.denied
              ? 'Permisos denegados permanentemente'
              : 'Permisos no otorgados';
        });

        // Solo mostrar diálogo UNA VEZ si los permisos están permanentemente denegados
        if (ps == PermissionState.denied &&
            !_hasShownDialog &&
            !_isDialogOpen) {
          _hasShownDialog = true;
          _showPermanentDenialDialog();
        }
      }
    } catch (e) {
      debugPrint('Error al verificar permisos: $e');
      if (!mounted) return;

      setState(() {
        _permissionsGranted = false;
        _isLoading = false;
        _isCheckingPermissions = false;
        _statusMessage = 'Error al verificar permisos';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPermanentDenialDialog() {
    _isDialogOpen = true; // ← NUEVO: Marcar que el diálogo está abierto

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permisos requeridos'),
        content: const Text(
          'La app necesita acceso a fotos y videos para funcionar. '
          'Por favor, habilita los permisos en Configuración.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _isDialogOpen = false; // ← NUEVO: Marcar que se cerró
              setState(() => _hasShownDialog = false);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _isDialogOpen =
                  false; // ← NUEVO: Marcar que se cerró antes de ir a Settings
              openAppSettings();
              // Mantener _hasShownDialog = true para que al volver chequee permisos
            },
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    ).then((_) {
      // ← NUEVO: Por si el diálogo se cierra de otra forma
      _isDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Permisos'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Verificando permisos...'),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _permissionsGranted
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      size: 80,
                      color: _permissionsGranted ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            _permissionsGranted ? Colors.green : Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (!_permissionsGranted) ...[
                      const Text(
                        'Esta app necesita acceso a tus fotos y videos para mostrar tu galería.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed:
                            _isCheckingPermissions ? null : _checkPermissions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Solicitar permisos'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          _hasShownDialog = true;
                          openAppSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Abrir configuración'),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          // Aquí irá la navegación a GalleryScreen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Próximo paso: Cargar galería (Módulo 2)'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Ir a Galería'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
