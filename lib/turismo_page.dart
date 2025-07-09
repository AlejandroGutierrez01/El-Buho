import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'detalle_lugar.dart';
import 'services/auth_service.dart';
import 'services/image_service.dart';
import 'services/location_service.dart';
import 'login_page.dart';

class TurismoPage extends StatefulWidget {
  const TurismoPage({super.key});

  @override
  State<TurismoPage> createState() => _TurismoPageState();
}

class _TurismoPageState extends State<TurismoPage> {
  final _formKey = GlobalKey<FormState>();
  String nombre = '';
  String descripcion = '';
  int valor = 0;
  String imagenUrl = 'null';
  bool _showForm = false;

  final _supabase = Supabase.instance.client;

  List<File> _selectedImages = [];
  String? _currentLocationLink;
  bool _isPublisher = false;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await AuthService.getUserProfile();
    final isPublisher = await AuthService.isPublisher();
    if (!mounted) return;
    print('Debug - Usuario actual: ${AuthService.currentUser?.email}');
    print('Debug - Perfil: $profile');
    print('Debug - Es publicador: $isPublisher');

    setState(() {
      _userProfile = profile;
      _isPublisher = isPublisher;
    });
  }

  Future<void> _agregarLugar() async {
    if (!_isPublisher) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Debes registrarte como publicador para agregar lugares.',
            ),
          ),
        );
      }
      return;
    }

    if (_formKey.currentState!.validate() && valor > 0) {
      _formKey.currentState!.save();

      try {
        List<String> imageUrls = [];
        if (_selectedImages.isNotEmpty) {
          imageUrls = await ImageService.uploadMultipleImages(
            _selectedImages,
            'imagenesturismo',
          );
        }

        final dataToInsert = {
          'lugar': nombre,
          'descripcion': descripcion,
          'valor': valor,
          'imagenUrl': imagenUrl.isNotEmpty ? imagenUrl : "https://cdn-icons-png.flaticon.com/512/8136/8136031.png",
          'imagenesUrl': imageUrls.isNotEmpty ? imageUrls : null,
          'ubicacionUrl': _currentLocationLink,
          'publicadoPor': AuthService.currentUser?.id,
        };

        await _supabase.from('turismo_lugares').insert(dataToInsert);

        _formKey.currentState!.reset();
        setState(() {
          valor = 0;
          _showForm = false;
          _selectedImages = [];
          _currentLocationLink = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lugar agregado exitosamente')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al agregar lugar: $error')),
          );
        }
      }
    }
  }

  // Método para seleccionar imágenes
  Future<void> _selectImages() async {
    final images = await ImageService.showImageOptions(context);
    if (images != null) {
      setState(() {
        _selectedImages = images;
      });
    }
  }

  // Método para obtener ubicación actual
  Future<void> _getCurrentLocation() async {
    try {
      final locationLink = await LocationService.getCurrentLocationLink();
      if (locationLink != null) {
        setState(() {
          _currentLocationLink = locationLink;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ubicación obtenida exitosamente')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo obtener la ubicación')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    }
  }

  // Método para cerrar sesión
  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Widget _buildStarRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calificación',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 92, 92, 92),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  valor = index + 1;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star,
                  size: 35,
                  color: index < valor
                      ? Colors.amber
                      : const Color.fromARGB(255, 252, 239, 156),
                ),
              ),
            );
          }),
        ),
        if (valor == 0)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Seleccione una calificación',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildFormOverlay() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7, // Tamaño inicial del 70% de la pantalla
      minChildSize: 0.5, // Tamaño mínimo del 50%
      maxChildSize: 0.9, // Tamaño máximo del 90%
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de arrastre
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Barra superior con título y botón cerrar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Agregar lugar turístico',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showForm = false;
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Campos del formulario
                    Column(
                      children: [
                        // Campo lugar (arriba)
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Lugar',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Ingrese un nombre' : null,
                          onSaved: (value) => nombre = value!,
                        ),
                        const SizedBox(height: 12),

                   
                        // Campo descripción
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          maxLines: 2,
                          validator: (value) =>
                              value!.isEmpty ? 'Ingrese una descripción' : null,
                          onSaved: (value) => descripcion = value!,
                        ),
                        const SizedBox(height: 16),

                        // Calificación con estrellas
                        _buildStarRating(),
                        const SizedBox(height: 16),

                        // Sección de imágenes
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Imágenes ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _selectImages,
                                      icon: const Icon(
                                        Icons.add_photo_alternate,
                                      ),
                                      label: const Text('Agregar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isPublisher
                                            ? const Color(0xFF1976D2)
                                            : Colors.grey,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_selectedImages.isNotEmpty) ...[
                                  Text(
                                    '${_selectedImages.length} imagen(es) seleccionada(s)',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 80,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              _selectedImages[index],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ] else
                                  const Text(
                                    'Opcional: Hasta 5 imágenes',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sección de ubicación
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Ubicación',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _getCurrentLocation,
                                      icon: const Icon(Icons.location_on),
                                      label: const Text('Obtener'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isPublisher
                                            ? const Color(0xFF1976D2)
                                            : Colors.grey,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_currentLocationLink != null)
                                  Text(
                                    'Ubicación obtenida ✓',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 14,
                                    ),
                                  )
                                else
                                  const Text(
                                    'Opcional: Toca para obtener ubicación actual',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Botón agregar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: valor > 0 ? _agregarLugar : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isPublisher
                                  ? const Color(0xFF1976D2)
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Agregar lugar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),

                        // Espacio adicional para el teclado
                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom > 0
                              ? 200
                              : 50,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('El Búho - Lugares Turísticos'),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadUserProfile,
            icon: const Icon(Icons.refresh),
          ),
          if (_userProfile == null || _userProfile?['rol'] != 'publicador')
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(
                      mensajeInicial: 'Debes iniciar sesión como publicador',
                    ),
                  ),
                );
              },
            ),
          if (_userProfile != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') _logout();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(_userProfile!['nombre'] ?? 'Usuario'),
                    subtitle: Text(_userProfile!['rol'] ?? 'visitante'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Cerrar sesión'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase
                .from('turismo_lugares')
                .stream(primaryKey: ['id']).order('lugar'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF43A047),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error al cargar lugares'));
              }

              final lugares = snapshot.data ?? [];
              if (lugares.isEmpty) {
                return const Center(
                  child: Text(
                    'Aún no hay lugares turísticos disponibles',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: lugares.length,
                itemBuilder: (context, index) {
                  final data = lugares[index];
                  final rating =
                      (data['valor'] is int) ? data['valor'] as int : 0;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (data['imagenesUrl'] != null &&
                                data['imagenesUrl'].isNotEmpty)
                            ? Image.network(
                                data['imagenesUrl'][0],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: const Color(0xFFEEEEEE),
                                child: const Icon(Icons.place,
                                    size: 30, color: Colors.grey),
                              ),
                      ),
                      title: Text(
                        data['lugar'] ?? 'Sin nombre',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            data['descripcion'] ?? 'Sin descripción',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: i < rating
                                    ? Colors.amber
                                    : Colors.grey[300],
                              );
                            }),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleLugarPage(data: data),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          if (_showForm) _buildFormOverlay(),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: _showForm ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.extended(
          onPressed: _isPublisher
              ? () => setState(() => _showForm = true)
              : () {
                  final currentUser = AuthService.currentUser;
                  if (currentUser == null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(
                          mensajeInicial: 'Debes iniciar sesión',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Debes ser publicador para agregar lugares.',
                        ),
                      ),
                    );
                  }
                },
          backgroundColor: _isPublisher
              ? const Color(0xFF1976D2)
              : const Color.fromARGB(255, 153, 153, 153),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo lugar'),
        ),
      ),
    );
  }
}
