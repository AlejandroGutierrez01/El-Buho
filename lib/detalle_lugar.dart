import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';

class DetalleLugarPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const DetalleLugarPage({super.key, required this.data});

  @override
  State<DetalleLugarPage> createState() => _DetalleLugarPageState();
}

class _DetalleLugarPageState extends State<DetalleLugarPage> {
  final _supabase = Supabase.instance.client;
  final _resenaController = TextEditingController();
  bool _isPublisher = false;
  List<Map<String, dynamic>> _resenas = [];
  bool _isLoadingResenas = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadResenas();
  }

  @override
  void dispose() {
    _resenaController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final isPublisher = await AuthService.isPublisher();
    setState(() {
      _isPublisher = isPublisher;
    });
  }

  Future<void> _loadResenas() async {
    setState(() {
      _isLoadingResenas = true;
    });
    try {
      final resenasPrincipales = await _supabase
          .from('turismo_resenas')
          .select(
              '*, perfil:turismo_perfiles!turismo_resenas_usuario_id_fkey(nombre)')
          .eq('lugar_id', widget.data['id'])
          .isFilter('resena_padre', null)
          .order('created_at', ascending: false);

      final respuestas = await _supabase
          .from('turismo_resenas')
          .select(
              '*, perfil:turismo_perfiles!turismo_resenas_usuario_id_fkey(nombre)')
          .eq('lugar_id', widget.data['id'])
          .not('resena_padre', 'is', null);

      final respuestasPorPadre = <int, List<Map<String, dynamic>>>{};
      for (final resp in respuestas) {
        final padreId = resp['resena_padre'];
        if (padreId != null) {
          respuestasPorPadre.putIfAbsent(padreId, () => []).add(resp);
        }
      }

      for (final resena in resenasPrincipales) {
        final resenaId = resena['id'];
        resena['respuestas'] = respuestasPorPadre[resenaId] ?? [];
      }

      setState(() {
        _resenas = List<Map<String, dynamic>>.from(resenasPrincipales);
        _isLoadingResenas = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingResenas = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cargando reseñas: $e')));
      }
    }
  }

  Future<void> _agregarResena({int? resenaPadre}) async {
    if (_resenaController.text.trim().isEmpty) return;
    try {
      await _supabase.from('turismo_resenas').insert({
        'lugar_id': widget.data['id'],
        'usuario_id': AuthService.currentUser!.id,
        'contenido': _resenaController.text.trim(),
        'resena_padre': resenaPadre,
      });
      _resenaController.clear();
      await _loadResenas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(resenaPadre == null
                ? 'Reseña agregada'
                : 'Respuesta agregada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data['lugar'] ?? 'Lugar turístico'),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),
            const SizedBox(height: 20),
            _buildTitleAndRating(),
            const SizedBox(height: 20),
            _buildDescription(),
            const SizedBox(height: 30),
            _buildReviewsSection(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Regresar', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    final List<String> images = [];

    // Agregar imágenes desde imagenesUrl si existen
    if (widget.data['imagenesUrl'] != null) {
      final additionalImages = List<String>.from(widget.data['imagenesUrl']);
      images.addAll(additionalImages);
    }

    // Si no hay imágenes, mostrar placeholder
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.image_not_supported,
          size: 100,
          color: Colors.grey,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleAndRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(widget.data['lugar'] ?? 'Sin nombre',
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(widget.data['valor']?.toString() ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Descripción',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(widget.data['descripcion'] ?? 'Sin descripción',
            style: const TextStyle(fontSize: 16, height: 1.6)),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reseñas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (_isPublisher) _buildReviewInputCard(),
        const SizedBox(height: 16),
        if (_isLoadingResenas)
          const Center(child: CircularProgressIndicator())
        else if (_resenas.isEmpty)
          const Center(
              child: Text('No hay reseñas aún',
                  style: TextStyle(color: Colors.grey)))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _resenas.length,
            itemBuilder: (context, index) => _buildReviewItem(_resenas[index]),
          ),
      ],
    );
  }

  Widget _buildReviewInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _resenaController,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Escribe tu reseña...',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _agregarResena(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2)),
                child: const Text('Agregar reseña',
                  style: TextStyle(color: Colors.white,)
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> resena) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 6),
              Text(resena['perfil']?['nombre'] ?? 'Usuario anónimo',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(_formatDate(resena['created_at']),
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(resena['contenido'] ?? '', style: const TextStyle(fontSize: 15)),
          if (_isPublisher)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showReplyDialog(resena['id']),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Responder'),
              ),
            ),
          if (resena['respuestas'] != null && resena['respuestas'].isNotEmpty)
            ...resena['respuestas'].map<Widget>((respuesta) => Container(
                  margin: const EdgeInsets.only(left: 20, top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16),
                            const SizedBox(width: 4),
                            Text(respuesta['perfil']?['nombre'] ?? 'Anónimo',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13)),
                            const Spacer(),
                            Text(_formatDate(respuesta['created_at']),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(respuesta['contenido'] ?? '',
                            style: const TextStyle(fontSize: 14)),
                      ]),
                )),
        ]),
      ),
    );
  }

  void _showReplyDialog(int resenaId) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responder reseña'),
        content: TextField(
            controller: replyController,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Escribe tu respuesta...',
                border: OutlineInputBorder())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resenaController.text = replyController.text;
                _agregarResena(resenaPadre: resenaId);
              },
              child: const Text('Responder')),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
