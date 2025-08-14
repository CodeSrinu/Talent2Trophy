import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InviteButton extends StatelessWidget {
  final String playerId;
  final String scoutId;
  const InviteButton({super.key, required this.playerId, required this.scoutId});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.mail_outline),
      label: const Text('Invite'),
      onPressed: () => _openDialog(context),
    );
  }

  void _openDialog(BuildContext context) {
    final msgCtrl = TextEditingController();
    DateTime? trialDate;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Send Invite'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: msgCtrl,
                decoration: const InputDecoration(hintText: 'Message (optional)')
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(trialDate == null ? 'No trial date' : 'Trial: ${trialDate!.toLocal().toString().split(' ').first}')),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () async {
                      final now = DateTime.now();
                      final pick = await showDatePicker(
                        context: ctx,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                        initialDate: now.add(const Duration(days: 7)),
                      );
                      if (pick != null) {
                        trialDate = pick;
                        (ctx as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('invites').add({
                  'fromScoutId': scoutId,
                  'toPlayerId': playerId,
                  'message': msgCtrl.text.trim(),
                  'trialDate': trialDate == null ? null : Timestamp.fromDate(trialDate!),
                  'status': 'sent',
                  'createdAt': Timestamp.now(),
                });
                // Create seed messages subcollection doc? Not required.
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite sent!')),
                  );
                }
              },
              child: const Text('Send'),
            )
          ],
        );
      }
    );
  }
}

