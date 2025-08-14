import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '_progress_sparkline.dart';

class PlayerHomeScreen extends ConsumerStatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  ConsumerState<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends ConsumerState<PlayerHomeScreen> {
  List<double> _recentScores() {
    // Pull latest scores from local video repository (sorted by created_at DESC)
    // Note: This is a sync wrapper around async; for production, move to a provider/async build.
    // For now, we show up to last 7 completed analysis scores.
    // If not available, we fallback to user.topAiScore.
    final user = ref.read(currentUserProvider).value;
    final latest = user?.topAiScore;
    // We can't do async here; return best-effort with top score only to avoid frame rebuild complications.
    if (latest == null) return const [];
    return [latest];
  }

  void _handleRecordingNavigation(BuildContext context) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    // Check if profile is complete before allowing recording
    final isProfileComplete = user.sport != null &&
                             user.gender != null &&
                             user.region != null &&
                             user.age != null;

    if (!isProfileComplete) {
      _showEnhancedProfileCompletionDialog(context);
      return;
    }

    // Profile is complete, proceed to recording
    final chosenSport = user.sport ?? 'Football';
    context.go('/record/$chosenSport');
  }

  void _showEnhancedProfileCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                padding: const EdgeInsets.all(4),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You must complete your profile before recording videos.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please complete the following required fields:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text('• Sport selection', style: TextStyle(fontSize: 13)),
            const Text('• Gender', style: TextStyle(fontSize: 13)),
            const Text('• Region/Location', style: TextStyle(fontSize: 13)),
            const Text('• Age', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/profile');
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Complete Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasShownProfileDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfileCompletion());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset dialog flag when returning from profile screen
    // This ensures the popup logic re-evaluates properly
    _hasShownProfileDialog = false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfileCompletion());
  }

  void _checkProfileCompletion() {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    // Only show profile completion dialog if:
    // 1. User has never completed initial profile setup AND
    // 2. Profile is actually incomplete AND
    // 3. We haven't shown the dialog in this session
    final isProfileIncomplete = user.isPlayer && (
      user.sport == null ||
      user.gender == null ||
      user.region == null ||
      user.age == null
    );

    final shouldShowDialog = !user.hasCompletedInitialProfile &&
                            isProfileIncomplete &&
                            !_hasShownProfileDialog;

    if (shouldShowDialog) {
      _hasShownProfileDialog = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Expanded(child: Text('Complete Your Profile')),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ],
          ),
          content: const Text('Please complete your profile with sport, gender, region, and age to unlock full features.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/profile');
              },
              child: const Text('Update Profile'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    // Reset dialog flag when profile becomes complete
    if (user != null && user.isPlayer) {
      final isComplete = user.sport != null &&
                        user.gender != null &&
                        user.region != null &&
                        user.age != null;
      if (isComplete && _hasShownProfileDialog) {
        _hasShownProfileDialog = false;
      }
    }

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final hasVideo = user.hasUploadedVideo;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: hasVideo ? _experiencedLayout(context, user.sport) : _newPlayerLayout(context, user.sport),
    );
  }

  Widget _newPlayerLayout(BuildContext context, String? sport) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Hero Illustration Section
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Background Pattern
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppConstants.primaryColor.withValues(alpha: 0.1),
                          AppConstants.secondaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
                // Main Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hero Illustration Placeholder
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          sport == 'Kabaddi' ? Icons.sports_kabaddi : Icons.sports_soccer,
                          size: 50,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Welcome Text
                      Text(
                        'Welcome to Talent2Trophy!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your journey to greatness starts here',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // CTA Button
                      SizedBox(
                        width: 180,
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const FittedBox(child: Text('Start Recording')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _handleRecordingNavigation(context),
                        ),
                      ),
                    ],
                  ),
                ),
                // Decorative Elements

                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppConstants.secondaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: AppConstants.secondaryColor,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Getting Started Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.rocket_launch,
                        color: AppConstants.successColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Getting Started',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStepItem(
                  context,
                  '1',
                  'Record Your First Drill',
                  'Show off your skills with a video recording',
                  Icons.videocam,
                ),
                const SizedBox(height: 12),
                _buildStepItem(
                  context,
                  '2',
                  'Get AI Analysis',
                  'Receive instant feedback on your performance',
                  Icons.psychology,
                ),
                const SizedBox(height: 12),
                _buildStepItem(
                  context,
                  '3',
                  'Track Progress',
                  'Monitor your improvement over time',
                  Icons.trending_up,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Featured Drills Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.sports,
                        color: AppConstants.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Popular Drills to Try',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _getSportSpecificDrills(sport),
                  ),
                ),
              ],
            ),
            ),
        ],
      ),
    );
  }

  Widget _experiencedLayout(BuildContext context, String? sport) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: AppConstants.accentColor),
            title: const Text('Latest AI Score'),
            subtitle: const Text('Keep going! Every drill makes you better.'),
            trailing: Text(
              (ref.watch(currentUserProvider).value?.topAiScore)?.toStringAsFixed(1) ?? '--',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ProgressSparkline(scores: _recentScores()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.leaderboard),
            title: const Text('Leaderboard Rank'),
            subtitle: const Text('See how you stack up against the best'),
            trailing: const Text('#--'),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.fiber_manual_record),
          label: const Text('Record Another Drill'),
          onPressed: () => _handleRecordingNavigation(context),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.video_library),
          label: const Text('Open Library'),
          onPressed: () => context.go('/library'),
        ),
      ],
    );
  }

  List<Widget> _getSportSpecificDrills(String? sport) {
    if (sport == 'Kabaddi') {
      return const [
        _DrillChip('Raid Entry', Icons.sports_kabaddi),
        _DrillChip('Tackle', Icons.sports_kabaddi),
        _DrillChip('Chain Formation', Icons.sports_kabaddi),
        _DrillChip('Bonus Point', Icons.sports_kabaddi),
        _DrillChip('Defensive Stance', Icons.sports_kabaddi),
        _DrillChip('Quick Movement', Icons.sports_kabaddi),
      ];
    } else {
      // Default to Football drills
      return const [
        _DrillChip('Kick', Icons.sports_soccer),
        _DrillChip('Juggling', Icons.sports_soccer),
        _DrillChip('Dribbling', Icons.sports_soccer),
        _DrillChip('Passing', Icons.sports_soccer),
        _DrillChip('Shooting', Icons.sports_soccer),
        _DrillChip('Ball Control', Icons.sports_soccer),
      ];
    }
  }

  Widget _buildStepItem(BuildContext context, String number, String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        Icon(
          icon,
          color: AppConstants.primaryColor.withValues(alpha: 0.6),
          size: 20,
        ),
      ],
    );
  }
}

class _DrillChip extends ConsumerWidget {
  final String label;
  final IconData icon;

  const _DrillChip(this.label, this.icon, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () => _showDrillDetails(context, ref, label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDrillDetails(BuildContext context, WidgetRef ref, String drillName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(drillName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder for drill video
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_library, size: 48, color: AppConstants.primaryColor),
                    SizedBox(height: 8),
                    Text('Sample Drill Video', style: TextStyle(color: AppConstants.primaryColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Drill metrics
            Text('Drill Metrics:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildMetricRow('Difficulty', 'Intermediate'),
            _buildMetricRow('Duration', '2-3 minutes'),
            _buildMetricRow('Focus Area', 'Technique & Speed'),
            _buildMetricRow('Success Rate', '85%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Re-use the same guard as Start Recording
              final user = ref.read(currentUserProvider).value;
              if (user == null) return;
              final isComplete = user.sport != null && user.gender != null && user.region != null && user.age != null;
              if (!isComplete) {
                // Show the parent dialog present in PlayerHome (using Navigator to close and reopen not ideal here)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please complete your profile to record this drill.')),
                );
                context.go('/profile');
                return;
              }
              final chosenSport = user.sport ?? 'Football';
              context.go('/record/$chosenSport');
            },
            child: const Text('Try This Drill'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}