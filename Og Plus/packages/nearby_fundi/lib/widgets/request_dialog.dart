// widgets/request_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/service_provider.dart';
import '../providers/request_provider.dart';
import '../models/technician.dart';
import '../models/service.dart';
import '../config/app_theme.dart';
import '../services/location_service.dart';
import '../utils/auth_guard.dart';
import '../utils/contact_validator.dart';

class RequestDialog extends StatefulWidget {
  final Technician technician;

  const RequestDialog({super.key, required this.technician});

  @override
  State<RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<RequestDialog> {
  final TextEditingController _descController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Listenable to track contact info errors dynamically
  final ValueNotifier<String?> _contactError = ValueNotifier<String?>(null);

  int? _selectedServiceId;
  int? _selectedCategoryId;

  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _errorMessage;

  List<ServiceCategory> _availableCategories = [];

  String _locale = 'en';
  bool _localeReady = false;

  // Job location (GPS only)
  double? _lat;
  double? _lng;
  String? _locationLabel;
  bool _locating = false;

  // ═════════════════════ LOGIC (unchanged) ═════════════════════

  @override
  void initState() {
    super.initState();

    // Only one service? Pre-select it.
    final services = widget.technician.serviceObjects;
    if (services.length == 1) _selectedServiceId = services.first.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localeReady) {
      _locale = Localizations.localeOf(context).languageCode;
      _localeReady = true;
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      await context.read<ServiceProvider>().fetchServices(locale: _locale);
      if (mounted && _selectedServiceId != null) {
        _updateCategories(_selectedServiceId);
      }
    } catch (_) {
      // Provider not in tree – categories stay empty
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _contactError.dispose();
    super.dispose();
  }

  void _updateCategories(int? serviceId) {
    if (serviceId == null) {
      setState(() {
        _availableCategories = [];
        _selectedCategoryId = null;
      });
      return;
    }

    try {
      final categories =
      context.read<ServiceProvider>().getCategoriesForService(serviceId);
      setState(() {
        _availableCategories = categories;
        _selectedCategoryId = null; // optional
      });
    } catch (_) {
      setState(() {
        _availableCategories = [];
        _selectedCategoryId = null;
      });
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final pos = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationLabel = 'My current location';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submitRequest() async {
    final l10n = AppLocalizations.of(context);
    final pleaseSelect = l10n?.pleaseSelectService ?? 'Please select a service';
    final failedLabel = l10n?.failed ?? 'Something went wrong';

    if (!AuthGuard.ensure(context, message: 'Sign in to send a request.')) {
      return;
    }

    // Ensure no contact info bypassed the live check
    final contactCheck = ContactValidator.validate(_descController.text);
    if (contactCheck != null) {
      _contactError.value = contactCheck;
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedServiceId == null) {
      setState(() => _errorMessage = pleaseSelect);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    bool success = false;
    String? err;

    try {
      final provider = context.read<RequestProvider>();

      success = await provider.createRequest(
        technicianId: widget.technician.id,
        serviceId: _selectedServiceId!,
        description: _descController.text.trim(),
        categoryId: _selectedCategoryId,
        latitude: _lat,
        longitude: _lng,
      );

      if (!success) err = provider.error ?? failedLabel;
    } catch (e) {
      err = e.toString();
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      if (success) {
        _isSuccess = true;
      } else {
        _errorMessage = err ?? failedLabel;
      }
    });
  }

  void _closeDialog() => Navigator.of(context).pop();

  // ═════════════════════ UI HELPERS ═════════════════════

  InputDecoration _fieldDecoration(
      ThemeData theme, {
        required String hint,
        required IconData icon,
        String? label,
        bool alignLabelWithHint = false,
        double vertical = 12,
      }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
      border: border(Colors.transparent),
      enabledBorder: border(theme.dividerColor),
      focusedBorder: border(AppTheme.primary, 2),
      errorBorder: border(AppTheme.error),
      focusedErrorBorder: border(AppTheme.error, 2),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: vertical),
    );
  }

  Widget _label(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Tinted box painted on a real Material surface, so ink splashes and
  /// tile/button backgrounds inside it are never hidden by a colored
  /// Container/DecoratedBox.
  Widget _tintedBox({
    required Color color,
    required Widget child,
    double radius = 12,
    double fill = 0.08,
    bool outlined = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  }) {
    return Material(
      color: color.withOpacity(fill),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: outlined
            ? BorderSide(color: color.withOpacity(0.2))
            : BorderSide.none,
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  ButtonStyle _buttonStyle({double elevation = 2}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppTheme.primary.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: elevation,
    );
  }

  Widget _header(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.handyman_rounded,
              color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
        if (!_isSubmitting && !_isSuccess)
          IconButton(
            icon: Icon(Icons.close_rounded, color: theme.hintColor, size: 22),
            onPressed: _closeDialog,
          ),
      ],
    );
  }

  // ═════════════════════ BUILD ═════════════════════

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Fallback strings so the dialog never shows blank text
    final title = l10n?.requestThisFundi ?? 'Request this fundi';
    final selectService = l10n?.selectService ?? 'Select service';
    final noServices = l10n?.noServicesSelected ?? 'No services available';
    final pleaseSelect = l10n?.pleaseSelectService ?? 'Please select a service';
    final categoryLabel = l10n?.category ?? 'Category';
    final describeIssue = l10n?.describeIssue ?? 'Describe the issue';
    final describeHint = l10n?.describeHint ?? 'What needs to be fixed?';
    final submitLabel = l10n?.submitRequest ?? 'Submit request';
    final sendingLabel = l10n?.sendingToTechnician ?? 'Sending to technician…';
    final requestSent = l10n?.requestSent ?? 'Request sent';
    final awaiting = l10n?.awaitingResponse ?? 'Awaiting response';
    final doneLabel = l10n?.done ?? 'Done';

    final theme = Theme.of(context);
    final services = widget.technician.serviceObjects;
    final hasServices = services.isNotEmpty;

    // Responsive sizing
    final size = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final narrow = size.width < 360;
    final maxWidth = size.width >= 600 ? 480.0 : 420.0;
    final maxHeight = (size.height - keyboard - 48).clamp(280.0, 720.0);

    return Dialog(
      insetPadding:
      EdgeInsets.symmetric(horizontal: narrow ? 12 : 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.all(narrow ? 16 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header (pinned) ──
              _header(theme, title),
              const SizedBox(height: 16),

              // ── Body (scrolls) ──
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Form ──
                      if (!_isSubmitting && !_isSuccess)
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(theme, selectService),

                              if (!hasServices)
                                _tintedBox(
                                  color: Colors.orange,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded,
                                          color: Colors.orange, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          noServices,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                DropdownButtonFormField<int?>(
                                  value: _selectedServiceId,
                                  isExpanded: true,
                                  decoration: _fieldDecoration(
                                    theme,
                                    hint: selectService,
                                    icon: Icons.construction_rounded,
                                  ),
                                  items: [
                                    DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text(selectService),
                                    ),
                                    ...services.map(
                                          (service) => DropdownMenuItem<int?>(
                                        value: service.id,
                                        child: Text(service.name,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedServiceId = value;
                                      _errorMessage = null;
                                    });
                                    _updateCategories(value);
                                  },
                                  validator: (value) =>
                                  value == null ? pleaseSelect : null,
                                ),
                              const SizedBox(height: 16),

                              // ── Category (optional) ──
                              if (_availableCategories.isNotEmpty) ...[
                                _label(theme, categoryLabel),
                                DropdownButtonFormField<int?>(
                                  value: _selectedCategoryId,
                                  isExpanded: true,
                                  decoration: _fieldDecoration(
                                    theme,
                                    hint: categoryLabel,
                                    icon: Icons.category_rounded,
                                  ),
                                  items: [
                                    DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text(categoryLabel),
                                    ),
                                    ..._availableCategories.map(
                                          (category) => DropdownMenuItem<int?>(
                                        value: category.id,
                                        child: Text(
                                          category.getDisplayName(_locale),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategoryId = value;
                                      _errorMessage = null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              // ── Description ──
                              TextFormField(
                                controller: _descController,
                                maxLines: 4,
                                maxLength: 1000,
                                onChanged: (value) {
                                  // Check contact info dynamically as they type
                                  _contactError.value =
                                      ContactValidator.validate(value);
                                },
                                decoration: _fieldDecoration(
                                  theme,
                                  label: describeIssue,
                                  hint: describeHint,
                                  icon: Icons.description_outlined,
                                  alignLabelWithHint: true,
                                  vertical: 14,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().length < 5) {
                                    return describeIssue;
                                  }
                                  // Final form validation check
                                  return ContactValidator.validate(v);
                                },
                              ),

                              // Dynamic contact warning
                              ValueListenableBuilder<String?>(
                                valueListenable: _contactError,
                                builder: (context, error, child) {
                                  if (error == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        top: 4, bottom: 8),
                                    child: Text(
                                      error,
                                      style: const TextStyle(
                                        color: AppTheme.error,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 8),

                              // ── Job location ──
                              _tintedBox(
                                color: AppTheme.primary,
                                radius: 14,
                                fill: 0.06,
                                outlined: false,
                                padding:
                                const EdgeInsets.fromLTRB(12, 4, 4, 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        color: AppTheme.error, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _lat == null
                                            ? 'No job location set'
                                            : 'Job location: ${_locationLabel ?? ''}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed:
                                      _locating ? null : _useMyLocation,
                                      child: _locating
                                          ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                        CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                          : const Text('Use mine'),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Error ──
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 14),
                                _tintedBox(
                                  color: AppTheme.error,
                                  fill: 0.06,
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          color: AppTheme.error, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                              color: AppTheme.error,
                                              fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              // ── Submit ──
                              ValueListenableBuilder<String?>(
                                valueListenable: _contactError,
                                builder: (context, error, child) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      // Disable button if there's a contact error
                                      onPressed:
                                      error != null ? null : _submitRequest,
                                      style: _buttonStyle(),
                                      child: Text(
                                        submitLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                      // ── Loading ──
                      if (_isSubmitting) ...[
                        const SizedBox(height: 24),
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            sendingLabel,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Success ──
                      if (_isSuccess) ...[
                        const SizedBox(height: 8),
                        _tintedBox(
                          color: Colors.green,
                          radius: 16,
                          fill: 0.06,
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: 48),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  requestSent,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  awaiting,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${widget.technician.name} was notified by SMS and email.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: _closeDialog,
                                    style: _buttonStyle(elevation: 0),
                                    child: Text(
                                      doneLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
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
}