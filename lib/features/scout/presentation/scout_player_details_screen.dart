import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'widgets/invite_button.dart';

class ScoutPlayerDetailsScreen extends ConsumerWidget {
  final String playerId;
  const ScoutPlayerDetailsScreen({super.key, required this.playerId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Player Details')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('users').doc(playerId).get(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!.data() ?? {};
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((d['name'] ?? d['email'] ?? 'Player') as String, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Sport: ${d['sport'] ?? '-'}'),
                Text('Region: ${d['region'] ?? '-'}'),
                Text('Age: ${(d['age'] ?? '-') }'),
                const SizedBox(height: 12),
                Text('Top Score: ${(d['topAiScore'] ?? '--').toString()}'),
                const SizedBox(height: 16),
                if (me?.userType == 'scout') InviteButton(playerId: playerId, scoutId: me!.id),
              ],
            ),
          );
        },
      ),
    );
  }
}

