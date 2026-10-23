import 'package:flutter/material.dart';

import '../../models/delivery_model.dart';
import 'executive_repository.dart';

class FailedDeliveryScreen extends StatefulWidget {
  final DeliveryModel delivery;
  final ExecutiveRepository repository;
  const FailedDeliveryScreen({
    super.key,
    required this.delivery,
    required this.repository,
  });
  @override
  State<FailedDeliveryScreen> createState() => _FailedDeliveryScreenState();
}

class _FailedDeliveryScreenState extends State<FailedDeliveryScreen> {
  final _notes = TextEditingController();
  String? _reason;
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      setState(() => _error = 'Select a failure reason.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.updateStatus(
        widget.delivery,
        'FAILED',
        failureReason: _reason,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed delivery saved.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report failed delivery')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Reason *'),
          items: failureReasons
              .map(
                (reason) =>
                    DropdownMenuItem(value: reason, child: Text(reason)),
              )
              .toList(),
          onChanged: _busy
              ? null
              : (value) => setState(() {
                  _reason = value;
                  _error = null;
                }),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notes,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            alignLabelWithHint: true,
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const CircularProgressIndicator()
                : const Text('Save failed delivery'),
          ),
        ),
      ],
    ),
  );
}
