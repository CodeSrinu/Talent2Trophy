import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'widgets/invite_button.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'scout_player_details_screen.dart';

import '../../../core/constants/app_constants.dart';

class ScoutDashboardScreen extends ConsumerStatefulWidget {
  const ScoutDashboardScreen({super.key});

  @override
  ConsumerState<ScoutDashboardScreen> createState() => _ScoutDashboardScreenState();
}

  String _ageBucket(int age) {
    if (age < 12) return 'Under 12';
    if (age <= 14) return '12-14';
    if (age <= 17) return '15-17';
    if (age <= 20) return '18-20';
    if (age <= 25) return '21-25';
    return '26+';
  }

class _ScoutDashboardScreenState extends ConsumerState<ScoutDashboardScreen> {
  String? _sport;
  String? _ageGroup;
  String? _region;
  RangeValues _scoreRange = const RangeValues(0, 100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scout Dashboard'),
      ),
      body: Column(
        children: [
          _filters(context),
          Expanded(child: _results()),
        ],
      ),
    );
  }

  Widget _filters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DropdownButton<String?>(
                hint: const Text('Sport'),
                value: _sport,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...AppConstants.sportsTypes.map((sport) => DropdownMenuItem(value: sport, child: Text(sport))),
                ],
                onChanged: (v) => setState(() => _sport = v),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                hint: const Text('Age'),
                value: _ageGroup,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...AppConstants.ageGroups.map((ageGroup) => DropdownMenuItem(value: ageGroup, child: Text(ageGroup))),
                ],
                onChanged: (v) => setState(() => _ageGroup = v),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                hint: const Text('Region'),
                value: _region,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...AppConstants.regions.map((region) => DropdownMenuItem(value: region, child: Text(region))),
                ],
                onChanged: (v) => setState(() => _region = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Score'),
              const SizedBox(width: 12),
              Expanded(
                child: RangeSlider(
                  values: _scoreRange,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  labels: RangeLabels(
                    _scoreRange.start.toStringAsFixed(0),
                    _scoreRange.end.toStringAsFixed(0),
                  ),
                  onChanged: (v) => setState(() => _scoreRange = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _results() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('users')
      .where('userType', isEqualTo: 'player');
    if (_sport != null) query = query.where('sport', isEqualTo: _sport);
    if (_region != null) query = query.where('region', isEqualTo: _region);
    // Age group could be mapped from age number; for now we skip a precise mapping in query

    query = query.orderBy('topAiScore', descending: true).limit(20);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No players found'));
        }
        // Client-side filter by score range and age bucket if selected
        docs = docs.where((doc) {
          final d = doc.data();
          final score = (d['topAiScore'] is num) ? (d['topAiScore'] as num).toDouble() : 0.0;
          if (score < _scoreRange.start || score > _scoreRange.end) return false;
          if (_ageGroup != null) {
            final age = d['age'] as int?;
            if (age != null) {
              final bucket = _ageBucket(age);
              if (bucket != _ageGroup) return false;
            }
          }
          return true;
        }).toList();
        if (docs.isEmpty) {
          return const Center(child: Text('No players match filters'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final name = d['name'] ?? 'Player';
            final age = d['age'];
            final sport = d['sport'] ?? '-';
            final score = d['topAiScore'];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text((name as String).isNotEmpty ? name[0].toUpperCase() : '?')),
                title: Text(name),
                subtitle: Text('$sport • ${(age ?? '--').toString()}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(score is num ? score.toStringAsFixed(1) : '--',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    InviteButton(playerId: docs[i].id, scoutId: ref.read(currentUserProvider).value?.id ?? ''),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScoutPlayerDetailsScreen(playerId: docs[i].id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

