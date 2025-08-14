import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.loginSuccess),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // App Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome Back!',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue your journey',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Email Field
                CustomTextFieldHelpers.email(
                  controller: _emailController,
                ),

                const SizedBox(height: 20),

                // Password Field
                CustomTextFieldHelpers.password(
                  controller: _passwordController,
                ),

                const SizedBox(height: 12),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to forgot password screen
                    },
                    child: Text(
                      'Forgot Password?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Login Button
                CustomButton(
                  text: 'Sign In',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppConstants.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Forgot Password Link
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your email first')),
                        );
                        return;
                      }
                      try {
                        await ref.read(authProvider.notifier).resetPassword(email);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset email sent! Check your inbox.'),
                            backgroundColor: AppConstants.successColor,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to send reset email: $e'),
                            backgroundColor: AppConstants.errorColor,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Forgot Password?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sign Up Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/register');
                        },
                        child: Text(
                          'Sign Up',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }


}
