import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/services/password_service.dart';
import 'package:rest/core/utils/app_toast.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _passwordService = PasswordService();

  bool _isSaving = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmation = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final message = await _passwordService.changePassword(
        contrasenaActual: _currentPasswordController.text,
        nuevaContrasena: _newPasswordController.text,
        confirmarContrasena: _confirmationController.text,
      );
      if (!mounted) return;
      AppToast.success(context, message);
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Cambiar contraseña',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42.w,
                            height: 42.w,
                            decoration: const BoxDecoration(
                              color: Color(0x1A4FC3F7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Color(0xFF326FB6),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Actualiza tu contraseña',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Por seguridad, confirma tu contraseña actual antes de crear una nueva.',
                        style: GoogleFonts.fredoka(
                          color: colors.onSurfaceVariant,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 22.h),
                      _passwordField(
                        label: 'Contraseña actual',
                        controller: _currentPasswordController,
                        visible: _showCurrentPassword,
                        onVisibilityChanged: () => setState(
                          () => _showCurrentPassword = !_showCurrentPassword,
                        ),
                        autofillHints: const [AutofillHints.password],
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Ingresa tu contraseña actual'
                            : null,
                      ),
                      SizedBox(height: 16.h),
                      _passwordField(
                        label: 'Nueva contraseña',
                        controller: _newPasswordController,
                        visible: _showNewPassword,
                        onVisibilityChanged: () =>
                            setState(() => _showNewPassword = !_showNewPassword),
                        autofillHints: const [AutofillHints.newPassword],
                        helperText: 'Mínimo 8 caracteres',
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'Debe tener al menos 8 caracteres';
                          }
                          if (value == _currentPasswordController.text) {
                            return 'La nueva contraseña debe ser diferente';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      _passwordField(
                        label: 'Confirmar nueva contraseña',
                        controller: _confirmationController,
                        visible: _showConfirmation,
                        onVisibilityChanged: () => setState(
                          () => _showConfirmation = !_showConfirmation,
                        ),
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _changePassword(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma tu nueva contraseña';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  height: 52.h,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _changePassword,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF326FB6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17.r),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_reset_rounded),
                    label: Text(
                      _isSaving ? 'Actualizando...' : 'Actualizar contraseña',
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onVisibilityChanged,
    required String? Function(String?) validator,
    required List<String> autofillHints,
    String? helperText,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: GoogleFonts.fredoka(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF326FB6)),
        suffixIcon: IconButton(
          tooltip: visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
          onPressed: onVisibilityChanged,
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: colors.onSurfaceVariant,
          ),
        ),
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF326FB6), width: 2),
        ),
      ),
    );
  }
}
