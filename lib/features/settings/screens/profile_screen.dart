import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/constants/profile_options.dart';
import 'package:rest/core/services/profile_service.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/utils/app_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _selectedCity;
  String? _selectedSemester;
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _profileService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _nombreController.text = profile.nombres;
        _apellidosController.text = profile.apellidos;
        _correoController.text = profile.correo;
        _telefonoController.text = profile.telefono ?? '';
        _selectedCity = profile.ciudad;
        _selectedSemester = profile.semestreActual;
        _birthDate = profile.fechaNacimiento;
        _isLoading = false;
      });
      UserSession.currentUserName = profile.nombres;
      await UserSession.persist();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_isUpdating || !(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedSemester == null || _birthDate == null) {
      AppToast.warning(
        context,
        'Selecciona tu semestre y fecha de nacimiento.',
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final date = _birthDate!;
      await _profileService.updateProfile({
        'nombres': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'semestre_actual': _selectedSemester,
        'fecha_nacimiento':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      });
      UserSession.currentUserName = _nombreController.text.trim();
      await UserSession.persist();
      if (!mounted) return;
      AppToast.success(context, 'Perfil actualizado correctamente.');
      await _loadProfile();
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          'No se pudo actualizar: ${error.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );
    if (selected != null && mounted) setState(() => _birthDate = selected);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Mi perfil',
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _ErrorState(message: _errorMessage!, onRetry: _loadProfile)
          : _buildForm(colors),
    );
  }

  Widget _buildForm(ColorScheme colors) {
    final appColors = context.appColors;
    final cityOptions = <String>{
      ...ProfileOptions.cities,
      if (_selectedCity?.trim().isNotEmpty == true) _selectedCity!,
    }.toList();
    final semesterOptions = <String>{
      ...ProfileOptions.semesters,
      if (_selectedSemester?.trim().isNotEmpty == true) _selectedSemester!,
    }.toList();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(22.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [appColors.accentTeal, appColors.accentBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26.r),
                    boxShadow: [
                      BoxShadow(
                        color: appColors.accentBlue.withValues(alpha: 0.2),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 88.w,
                        height: 88.w,
                        decoration: BoxDecoration(
                          color: appColors.overlayOnGradient.withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: appColors.overlayOnGradient.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: appColors.overlayOnGradient,
                          size: 48,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        '${_nombreController.text} ${_apellidosController.text}'
                            .trim(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: appColors.overlayOnGradient,
                          fontFamily: 'Fredoka',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        _correoController.text,
                        style: TextStyle(
                          color: appColors.overlayOnGradient.withValues(
                            alpha: 0.88,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
                _FormSection(
                  title: 'Información personal',
                  children: [
                    _textField(
                      label: 'Nombres',
                      controller: _nombreController,
                      icon: Icons.person_outline_rounded,
                      validator: _requiredName,
                    ),
                    SizedBox(height: 14.h),
                    _textField(
                      label: 'Apellidos',
                      controller: _apellidosController,
                      icon: Icons.badge_outlined,
                      validator: _requiredName,
                    ),
                    SizedBox(height: 14.h),
                    _textField(
                      label: 'Correo institucional',
                      controller: _correoController,
                      icon: Icons.alternate_email_rounded,
                      readOnly: true,
                      helperText: 'El correo de la cuenta no se puede editar.',
                    ),
                    SizedBox(height: 14.h),
                    _textField(
                      label: 'Teléfono',
                      controller: _telefonoController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.length < 7) {
                          return 'Ingresa un teléfono válido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 14.h),
                    _dateField(),
                  ],
                ),
                SizedBox(height: 16.h),
                _FormSection(
                  title: 'Información académica',
                  children: [
                    _dropdown(
                      label: 'Ciudad',
                      value: _selectedCity,
                      items: cityOptions,
                      icon: Icons.location_city_outlined,
                      onChanged: null,
                      helperText:
                          'La API actual todavía no permite cambiar la ciudad.',
                    ),
                    SizedBox(height: 14.h),
                    _dropdown(
                      label: 'Semestre actual',
                      value: _selectedSemester,
                      items: semesterOptions,
                      icon: Icons.school_outlined,
                      onChanged: (value) =>
                          setState(() => _selectedSemester = value),
                    ),
                  ],
                ),
                SizedBox(height: 22.h),
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: FilledButton.icon(
                    onPressed: _isUpdating ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: appColors.overlayOnGradient,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17.r),
                      ),
                    ),
                    icon: _isUpdating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: appColors.overlayOnGradient,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isUpdating ? 'Guardando…' : 'Guardar cambios',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    String? helperText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.fredoka(fontWeight: FontWeight.w500),
      decoration: _decoration(
        label: label,
        icon: icon,
        helperText: helperText,
        filledColor: readOnly
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?>? onChanged,
    String? helperText,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value != null && items.contains(value) ? value : null,
      isExpanded: true,
      decoration: _decoration(
        label: label,
        icon: icon,
        helperText: helperText,
        filledColor: onChanged == null
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: onChanged == null
          ? null
          : (selected) => selected == null ? 'Selecciona una opción' : null,
    );
  }

  Widget _dateField() {
    final date = _birthDate;
    final formatted = date == null
        ? 'Selecciona tu fecha'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _pickBirthDate,
      child: InputDecorator(
        decoration: _decoration(
          label: 'Fecha de nacimiento',
          icon: Icons.calendar_month_outlined,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatted,
                style: GoogleFonts.fredoka(
                  color: date == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? helperText,
    Color? filledColor,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperMaxLines: 2,
      prefixIcon: Icon(icon, color: colors.primary),
      filled: true,
      fillColor: filledColor ?? colors.surfaceContainerLow,
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
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
    );
  }

  String? _requiredName(String? value) {
    if ((value?.trim().length ?? 0) < 2) return 'Ingresa al menos 2 caracteres';
    return null;
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 50),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
