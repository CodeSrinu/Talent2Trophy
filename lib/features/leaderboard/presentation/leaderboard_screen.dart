import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _filter = 'All'; // All | Football | Kabaddi

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildFilters(context),
          if (me != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.person_pin, color: AppConstants.accentColor),
                  title: Text('You: ${me.displayName}'),
                  subtitle: Text('Major Sport: ${me.sport ?? '--'}'),
                  trailing: Text(
                    me.topAiScore?.toStringAsFixed(1) ?? '--',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('topAiScore', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                // Client-side filter to avoid Firestore composite index requirements
                final filtered = docs.where((d) {
                  final data = d.data();
                  final isPlayer = (data['userType'] ?? '') == 'player';
                  final score = data['topAiScore'];
                  final sport = data['sport'];
                  final scoreOk = score is num && score > 0;
                  final sportOk = _filter == 'All' || sport == _filter;
                  return isPlayer && scoreOk && sportOk;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No scores yet. Be the first to upload!'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final data = filtered[index].data();
                    final rank = index + 1;
                    final name = (data['name'] ?? data['email'] ?? '--') as String;
                    final sport = (data['sport'] ?? '--') as String;
                    final score = (data['topAiScore'] as num).toDouble();
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppConstants.primaryColor.withOpacity(0.08),
                          child: Text('$rank'),
                        ),
                        title: Text(name),
                        subtitle: Text('Sport: $sport'),
                        trailing: Text(
                          score.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: filtered.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final options = ['All', ...AppConstants.sportsTypes];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: options.map((o) {
          final selected = _filter == o;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(o),
              selected: selected,
              onSelected: (_) => setState(() => _filter = o),
              selectedColor: AppConstants.primaryColor.withOpacity(0.15),
            ),
          );
        }).toList(),
      ),
    );
  }
}

