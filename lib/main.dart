import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'screens/gallery_screen.dart';

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
  bool _isDialogOpen = false;
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
        if (_isDialogOpen && mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _isDialogOpen = false;
        }

        if (!mounted) return;
        setState(() {
          _permissionsGranted = true;
          _isLoading = false;
          _isCheckingPermissions = false;
          _hasShownDialog = false;
          _statusMessage = '¡Permisos otorgados correctamente!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Permisos otorgados - Listo para cargar galería'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _permissionsGranted = false;
          _isLoading = false;
          _isCheckingPermissions = false;
          _statusMessage = ps == PermissionState.denied
              ? 'Permisos denegados permanentemente'
              : 'Permisos no otorgados';
        });

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
    _isDialogOpen = true;

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
              _isDialogOpen = false;
              setState(() => _hasShownDialog = false);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _isDialogOpen = false;
              openAppSettings();
            },
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    ).then((_) {
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
                          // Navegar a GalleryScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GalleryScreen(),
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
