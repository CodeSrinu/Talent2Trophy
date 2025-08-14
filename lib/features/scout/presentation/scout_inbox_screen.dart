import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ScoutInboxScreen extends ConsumerWidget {
  const ScoutInboxScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).value;
    if (me == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Query<Map<String, dynamic>> invitesRef = FirebaseFirestore.instance.collection('invites');
    if (me.userType == 'player') {
      invitesRef = invitesRef.where('toPlayerId', isEqualTo: me.id);
    } else if (me.userType == 'scout') {
      invitesRef = invitesRef.where('fromScoutId', isEqualTo: me.id);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: invitesRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No invites yet'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final status = d['status'] ?? 'sent';
              final msg = d['message'] ?? '';
              final ts = (d['createdAt'] as Timestamp?)?.toDate();
              return Card(
                child: ListTile(
                  title: Text(msg.isEmpty ? 'Invite' : msg),
                  subtitle: Text('Status: $status • ${ts ?? ''}'),
                  trailing: me.userType == 'player' && status == 'sent' ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _updateStatus(docs[i].reference, 'accepted'),
                        child: const Text('Accept'),
                      ),
                      TextButton(
                        onPressed: () => _updateStatus(docs[i].reference, 'declined'),
                        child: const Text('Decline'),
                      ),
                    ],
                  ) : null,
                  onTap: () => _openThread(context, docs[i].reference.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatus(DocumentReference ref, String status) {
    ref.update({'status': status});
  }

  void _openThread(BuildContext context, String inviteId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _MessageThread(inviteId: inviteId)),
    );
  }
}

class _MessageThread extends ConsumerStatefulWidget {
  final String inviteId;
  const _MessageThread({required this.inviteId});
  @override
  ConsumerState<_MessageThread> createState() => _MessageThreadState();
}

class _MessageThreadState extends ConsumerState<_MessageThread> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).value;
    final messagesRef = FirebaseFirestore.instance.collection('invites')
      .doc(widget.inviteId).collection('messages').orderBy('createdAt');
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    final mine = d['senderId'] == me?.id;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: mine ? AppConstants.primaryColor.withValues(alpha: 0.1) : AppConstants.surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(d['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = _ctrl.text.trim();
                    if (text.isEmpty || me == null) return;
                    await FirebaseFirestore.instance.collection('invites')
                      .doc(widget.inviteId)
                      .collection('messages')
                      .add({
                        'senderId': me.id,
                        'text': text,
                        'createdAt': Timestamp.now(),
                      });
                    _ctrl.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

