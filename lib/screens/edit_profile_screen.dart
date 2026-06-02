import 'package:flutter/material.dart';

import 'confirm_password_change_screen.dart';
import '../services/auth_api_service.dart';
import '../theme/app_tokens.dart';

class EditProfileScreen extends StatefulWidget {
  final AuthSession session;

  const EditProfileScreen({
    super.key,
    required this.session,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  final AuthApiService _authApiService = const AuthApiService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.session.username;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authApiService.updateProfile(
        username: _usernameController.text,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmNewPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Sikertelen profilmódosítás.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Profil sikeresen frissítve.')),
      );

      if (result.passwordChangeConfirmationRequired) {
        final confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const ConfirmPasswordChangeScreen()),
        );

        if (!mounted) {
          return;
        }

        if (confirmed == true) {
          Navigator.of(context).pop(true);
          return;
        }
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saját adatok szerkesztése')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'E-mail: ${widget.session.email}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Felhasználónév',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'A felhasználónév nem lehet üres.';
                            }
                            if (text.length < 3) {
                              return 'Legalább 3 karakter szükséges.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Jelszó módosítás (opcionális)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Jelenlegi jelszó',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Új jelszó',
                            prefixIcon: Icon(Icons.lock_reset),
                          ),
                          validator: (value) {
                            final newPassword = value ?? '';
                            final currentPassword = _currentPasswordController.text;
                            final confirmPassword = _confirmNewPasswordController.text;
                            final wantsPasswordChange =
                                currentPassword.isNotEmpty ||
                                newPassword.isNotEmpty ||
                                confirmPassword.isNotEmpty;

                            if (!wantsPasswordChange) {
                              return null;
                            }
                            if (newPassword.isEmpty) {
                              return 'Add meg az új jelszót.';
                            }
                            if (newPassword.length < 6) {
                              return 'Legalább 6 karakter szükséges.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _confirmNewPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Új jelszó megerősítése',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                          ),
                          validator: (value) {
                            final confirm = value ?? '';
                            final currentPassword = _currentPasswordController.text;
                            final newPassword = _newPasswordController.text;
                            final wantsPasswordChange =
                                currentPassword.isNotEmpty ||
                                newPassword.isNotEmpty ||
                                confirm.isNotEmpty;

                            if (!wantsPasswordChange) {
                              return null;
                            }
                            if (currentPassword.isEmpty) {
                              return 'Add meg a jelenlegi jelszót.';
                            }
                            if (confirm.isEmpty) {
                              return 'Erősítsd meg az új jelszót.';
                            }
                            if (confirm != newPassword) {
                              return 'Az új jelszó és megerősítés nem egyezik.';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_isLoading ? 'Mentés...' : 'Mentés'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
