import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  String? _selectedSport;
  String? _selectedGender;
  String? _selectedRegion;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Auto-enter edit mode for new users with incomplete profiles
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfNewUser());
  }

  void _checkIfNewUser() {
    final user = ref.read(currentUserProvider).value;
    if (user != null && user.isPlayer) {
      // Check if user has incomplete profile (missing sport, gender, region, etc.)
      final hasIncompleteProfile = user.sport == null || 
                                  user.gender == null || 
                                  user.region == null ||
                                  user.age == null;
      
      if (hasIncompleteProfile) {
        setState(() {
          _isEditing = true;
        });
        
        // Show welcome message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome! Please complete your profile to get started.'),
              backgroundColor: AppConstants.successColor,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber ?? '';
      _bioController.text = user.bio ?? '';
      _ageController.text = user.age?.toString() ?? '';
      _heightController.text = user.height?.toString() ?? '';
      _weightController.text = user.weight?.toString() ?? '';
      // Validate sport value against available options
      _selectedSport = AppConstants.sportsTypes.contains(user.sport) ? user.sport : null;
      
      // Validate gender value against available options
      _selectedGender = AppConstants.genderOptions.contains(user.gender) ? user.gender : null;
      
      // Validate region value against available options
      _selectedRegion = AppConstants.regions.contains(user.region) ? user.region : null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final current = ref.read(currentUserProvider).value;

    // Enforce required fields for players
    if (current != null && current.isPlayer) {
      final missingSport = _selectedSport == null || _selectedSport!.isEmpty;
      if (missingSport) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your sport before saving.')),
        );
        return;
      }
    }

    setState(() { _isLoading = true; });

    try {
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'sport': _selectedSport,
        'gender': _selectedGender,
        'region': _selectedRegion,
      };

      // Numeric fields: if empty, explicitly set null to allow clearing
      updateData['age'] = _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null;
      updateData['height'] = _heightController.text.isNotEmpty ? double.tryParse(_heightController.text) : null;
      updateData['weight'] = _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null;

      await ref.read(authProvider.notifier).updateUserData(updateData);

      if (!mounted) return;

      // Reload user from backend/cache to reflect latest values in UI
      final updated = ref.read(currentUserProvider).value;

      setState(() {
        _isEditing = false;
        // Re-sync controllers with updated values to reflect changes immediately
        _nameController.text = updated?.name ?? _nameController.text;
        _phoneController.text = updated?.phoneNumber ?? _phoneController.text;
        _bioController.text = updated?.bio ?? _bioController.text;
        _ageController.text = updated?.age?.toString() ?? _ageController.text;
        _heightController.text = updated?.height?.toString() ?? _heightController.text;
        _weightController.text = updated?.weight?.toString() ?? _weightController.text;
        _selectedSport = AppConstants.sportsTypes.contains(updated?.sport) ? updated?.sport : _selectedSport;
        _selectedGender = AppConstants.genderOptions.contains(updated?.gender) ? updated?.gender : _selectedGender;
        _selectedRegion = AppConstants.regions.contains(updated?.region) ? updated?.region : _selectedRegion;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.profileUpdated),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/player'),
        ),
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppConstants.primaryColor,
                      child: user.profileImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                user.profileImageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    user.isPlayer ? Icons.person : Icons.search,
                                    size: 50,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              user.isPlayer ? Icons.person : Icons.search,
                              size: 50,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.displayName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.userType.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Basic Information
              Text(
                'Basic Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              CustomTextFieldHelpers.name(
                controller: _nameController,
                label: 'Full Name',
                enabled: _isEditing,
              ),

              const SizedBox(height: 16),

              CustomTextFieldHelpers.email(
                controller: TextEditingController(text: user.email),
                label: 'Email',
                enabled: false, // Email cannot be changed
              ),

              const SizedBox(height: 16),

              CustomTextFieldHelpers.phone(
                controller: _phoneController,
                enabled: _isEditing,
              ),

              const SizedBox(height: 32),

              // Player-specific fields (only show for players)
              if (user.isPlayer) ...[
                Text(
                  'Sports Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Sport Selection
                Text(
                  'Sport',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSport,
                  decoration: const InputDecoration(
                    hintText: 'Select your sport',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.sportsTypes.map((sport) {
                    return DropdownMenuItem(
                      value: sport,
                      child: Text(sport),
                    );
                  }).toList(),
                  onChanged: _isEditing ? (value) {
                    setState(() {
                      _selectedSport = value;
                    });
                  } : null,
                ),

                const SizedBox(height: 16),

                // Gender Selection
                Text(
                  'Gender',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    hintText: 'Select your gender',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.genderOptions.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: _isEditing ? (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  } : null,
                ),

                const SizedBox(height: 16),

                // Age, Height, Weight
                Row(
                  children: [
                    Expanded(
                      child: CustomTextFieldHelpers.number(
                        controller: _ageController,
                        label: 'Age',
                        hint: 'Enter age',
                        enabled: _isEditing,
                        maxLength: 2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFieldHelpers.number(
                        controller: _heightController,
                        label: 'Height (cm)',
                        hint: 'Enter height',
                        enabled: _isEditing,
                        maxLength: 5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextFieldHelpers.number(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        hint: 'Enter weight',
                        enabled: _isEditing,
                        maxLength: 5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Region Selection
                Text(
                  'Region',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedRegion,
                  decoration: const InputDecoration(
                    hintText: 'Select your region',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.regions.map((region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region),
                    );
                  }).toList(),
                  onChanged: _isEditing ? (value) {
                    setState(() {
                      _selectedRegion = value;
                    });
                  } : null,
                ),
              ],

              const SizedBox(height: 16),

              // Bio
              CustomTextFieldHelpers.multiline(
                controller: _bioController,
                label: 'Bio',
                hint: 'Tell us about yourself...',
                enabled: _isEditing,
                maxLines: 4,
              ),

              const SizedBox(height: 32),

              // Action Buttons
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        type: ButtonType.outline,
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                          });
                          _loadUserData(); // Reset to original values
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Save',
                        onPressed: _saveProfile,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                CustomButton(
                  text: 'Edit Profile',
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Logout button at bottom
              Align(
                alignment: Alignment.center,
                child: CustomButton(
                  text: 'Logout',
                  type: ButtonType.outline,
                  backgroundColor: AppConstants.errorColor,
                  textColor: Colors.white,
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (!mounted) return;
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                ),
              ),

              // Account Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Member since', 
                        '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
                      _buildInfoRow('Account type', user.userType.toUpperCase()),
                      if (user.isScout) ...[
                        _buildInfoRow('Verification status', 
                          user.verificationStatus?.toUpperCase() ?? 'PENDING'),
                        if (user.organization != null)
                          _buildInfoRow('Organization', user.organization!),
                      ],
                      if (user.isPlayer && user.achievements.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Achievements',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...user.achievements.map((achievement) => 
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: AppConstants.accentColor),
                                const SizedBox(width: 8),
                                Expanded(child: Text(achievement)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppConstants.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
