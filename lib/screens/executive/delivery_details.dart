import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/delivery_model.dart';
import '../../utils/app_constants.dart';
import 'executive_repository.dart';
import 'failed_delivery.dart';
import 'proof.dart';
import 'raise_escalation.dart';
import 'update_status.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  final DeliveryModel delivery;
  final ExecutiveRepository repository;
  const DeliveryDetailsScreen({
    super.key,
    required this.delivery,
    required this.repository,
  });
  @override
  Widget build(BuildContext context) {
    final proofRepository = repository is ExecutiveProofUploadRepository
        ? repository as ExecutiveProofUploadRepository
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          delivery.orderId.isEmpty ? 'Delivery details' : delivery.orderId,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            delivery.customerName.isEmpty
                ? 'Customer unavailable'
                : delivery.customerName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            delivery.status,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _Info(
            label: 'Address',
            value: '${delivery.address}\n${delivery.city}',
          ),
          _Info(label: 'Phone', value: delivery.customerPhone),
          _Info(label: 'Notes', value: delivery.notes),
          _Info(label: 'Failure reason', value: delivery.failureReason),
          _Info(
            label: 'Last updated',
            value: delivery.updatedAt?.toLocal().toString(),
          ),
          const SizedBox(height: 18),
          if (canMoveTo(delivery.status, 'PICKED UP') ||
              canMoveTo(delivery.status, 'OUT FOR DELIVERY') ||
              canMoveTo(delivery.status, 'DELIVERED'))
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UpdateStatusScreen(
                    delivery: delivery,
                    repository: repository,
                  ),
                ),
              ),
              icon: const Icon(Icons.sync),
              label: const Text('Update status'),
            ),
          if (delivery.status == DeliveryStatuses.outForDelivery) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FailedDeliveryScreen(
                    delivery: delivery,
                    repository: repository,
                  ),
                ),
              ),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report failed delivery'),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RaiseEscalationScreen(
                  delivery: delivery,
                  repository: repository,
                ),
              ),
            ),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Raise escalation'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProofScreen(
                  delivery: delivery,
                  onUpload: proofRepository != null
                      ? ({
                          required Uint8List bytes,
                          required String contentType,
                          required String extension,
                        }) => proofRepository.uploadProofBytes(
                          delivery: delivery,
                          bytes: bytes,
                          contentType: contentType,
                          extension: extension,
                        )
                      : null,
                ),
              ),
            ),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(
              delivery.proofImageUrl == null ? 'Add proof' : 'View proof',
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String? value;
  const _Info({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 3),
        Text(value?.isNotEmpty == true ? value! : 'Not available'),
      ],
    ),
  );
}
