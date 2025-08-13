import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../core/constants/app_constants.dart';

class ScoutDashboardScreen extends ConsumerStatefulWidget {
  const ScoutDashboardScreen({super.key});

  @override
  ConsumerState<ScoutDashboardScreen> createState() => _ScoutDashboardScreenState();
}

class _ScoutDashboardScreenState extends ConsumerState<ScoutDashboardScreen> {
  String? _sport;
  String? _ageGroup;
  String? _region;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
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
      child: Row(
        children: [
          DropdownButton<String?>(
            hint: const Text('Sport'),
            value: _sport,
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...AppConstants.sportsTypes.map((sport) => 
                DropdownMenuItem(value: sport, child: Text(sport))
              ),
            ],
            onChanged: (v) => setState(() => _sport = v),
          ),
          const SizedBox(width: 8),
          DropdownButton<String?>(
            hint: const Text('Age'),
            value: _ageGroup,
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...AppConstants.ageGroups.map((ageGroup) => 
                DropdownMenuItem(value: ageGroup, child: Text(ageGroup))
              ),
            ],
            onChanged: (v) => setState(() => _ageGroup = v),
          ),
          const SizedBox(width: 8),
          DropdownButton<String?>(
            hint: const Text('Region'),
            value: _region,
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              ...AppConstants.regions.map((region) => 
                DropdownMenuItem(value: region, child: Text(region))
              ),
            ],
            onChanged: (v) => setState(() => _region = v),
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
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No players found'));
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
                trailing: Text(score is num ? score.toStringAsFixed(1) : '--',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  // TODO: navigate to profile details for scouts
                },
              ),
            );
          },
        );
      },
    );
  }
}

