import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../../models/delivery_model.dart';

class ProofScreen extends StatelessWidget {
  final DeliveryModel delivery;
  final Future<String> Function({
    required Uint8List bytes,
    required String contentType,
    required String extension,
  })?
  onUpload;

  const ProofScreen({super.key, required this.delivery, this.onUpload});

  @override
  Widget build(BuildContext context) {
    return _ProofView(delivery: delivery, onUpload: onUpload);
  }
}

class _ProofView extends StatefulWidget {
  final DeliveryModel delivery;
  final Future<String> Function({
    required Uint8List bytes,
    required String contentType,
    required String extension,
  })?
  onUpload;

  const _ProofView({required this.delivery, required this.onUpload});

  @override
  State<_ProofView> createState() => _ProofViewState();
}

class _ProofViewState extends State<_ProofView> {
  bool _uploading = false;
  String? _error;

  Future<void> _selectAndUpload() async {
    if (widget.onUpload == null) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(source: source);
    if (image == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final bytes = await image.readAsBytes();
      final extension = _extensionFor(image.name);
      await widget.onUpload!(
        bytes: bytes,
        contentType: _contentTypeFor(extension),
        extension: extension,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof uploaded successfully.')),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = widget.onUpload != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery proof')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (widget.delivery.proofImageUrl != null)
              Image.network(
                widget.delivery.proofImageUrl!,
                errorBuilder: (_, error, stackTrace) =>
                    const Text('Proof image unavailable.'),
              )
            else
              const Text('No proof has been recorded for this delivery.'),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const Spacer(),
            if (canUpload)
              FilledButton.icon(
                onPressed: _uploading ? null : _selectAndUpload,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_uploading ? 'Uploading...' : 'Capture proof'),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Proof upload is unavailable for this repository.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _extensionFor(String name) {
    final value = name.toLowerCase().split('.').last;
    return {'jpeg', 'jpg', 'png', 'webp'}.contains(value) ? value : 'jpg';
  }

  static String _contentTypeFor(String extension) =>
      extension == 'png' ? 'image/png' : 'image/jpeg';
}
