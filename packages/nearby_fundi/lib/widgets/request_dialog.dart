// widgets/request_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/service_provider.dart';
import '../providers/request_provider.dart';
import '../providers/location_provider.dart';
import '../models/technician.dart';
import '../models/service.dart';
import '../config/app_theme.dart';

class RequestDialog extends StatefulWidget {
  final Technician technician;

  const RequestDialog({super.key, required this.technician});

  @override
  State<RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<RequestDialog> {
  final TextEditingController _descController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? _selectedServiceId;
  int? _selectedCategoryId;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _errorMessage;
  List<ServiceCategory> _availableCategories = [];
  String _locale = 'en';
  bool _localeReady = false;
  bool _categoryReadOnly = false;

  @override
  void initState() {
    super.initState();
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

  void _loadData() {
    if (!mounted) return;
    try {
      context.read<ServiceProvider>().fetchServices(locale: _locale);
    } catch (_) {
      // Provider not in tree (wrong navigator) – categories stay empty
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _updateCategories(int? serviceId) {
    if (serviceId == null) {
      setState(() {
        _availableCategories = [];
        _selectedCategoryId = null;
        _categoryReadOnly = false;
      });
      return;
    }

    try {
      final categories =
      context.read<ServiceProvider>().getCategoriesForService(serviceId);
      setState(() {
        _availableCategories = categories;
        if (categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
          _categoryReadOnly = true;
        } else {
          _selectedCategoryId = null;
          _categoryReadOnly = false;
        }
      });
    } catch (_) {
      setState(() {
        _availableCategories = [];
        _selectedCategoryId = null;
        _categoryReadOnly = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    final l10n = AppLocalizations.of(context);
    final pleaseSelect = l10n?.pleaseSelectService ?? 'Please select a service';
    final failedLabel = l10n?.failed ?? 'Something went wrong';

    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceId == null) {
      setState(() => _errorMessage = pleaseSelect);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    double? lat;
    double? lng;
    try {
      final position = context.read<LocationProvider>().position;
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (_) {}

    bool success = false;
    String? err;
    try {
      success = await context.read<RequestProvider>().createRequest(
        technicianId: widget.technician.id,
        serviceId: _selectedServiceId!,
        description: _descController.text.trim(),
        categoryId: _selectedCategoryId,
        latitude: lat,
        longitude: lng,
      );
      if (!success) {
        err = context.read<RequestProvider>().error ?? failedLabel;
      }
    } catch (e) {
      err = e.toString();
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _isSuccess = true;
        _isSubmitting = false;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        try {
          context.read<RequestProvider>().loadMyRequests();
        } catch (_) {}
      }
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = err ?? failedLabel;
      });
    }
  }

  void _closeDialog() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Fallback strings so dialog never shows blank spinner
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
    final retryLabel = l10n?.retry ?? 'Retry';

    final theme = Theme.of(context);
    final services = widget.technician.serviceObjects;
    final hasServices = services.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.cardColor,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.handyman_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
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
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.hintColor,
                        size: 22,
                      ),
                      onPressed: _closeDialog,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Form
              if (!_isSubmitting && !_isSuccess) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectService,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!hasServices)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  noServices,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<int?>(
                          value: _selectedServiceId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: selectService,
                            hintStyle: TextStyle(
                              color: theme.hintColor,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.construction_rounded,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor:
                            theme.colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(selectService),
                            ),
                            ...services.map(
                                  (service) => DropdownMenuItem<int?>(
                                value: service.id,
                                child: Text(service.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedServiceId = value;
                              _errorMessage = null;
                              _updateCategories(value);
                            });
                          },
                          validator: (value) =>
                          value == null ? pleaseSelect : null,
                        ),

                      if (_errorMessage != null &&
                          _errorMessage!.toLowerCase().contains('service'))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Category
                      if (_availableCategories.isNotEmpty) ...[
                        Text(
                          categoryLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int?>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: categoryLabel,
                            hintStyle: TextStyle(
                              color: theme.hintColor,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.category_rounded,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: _categoryReadOnly
                                ? theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.7)
                                : theme.colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: _availableCategories
                              .map(
                                (category) => DropdownMenuItem<int?>(
                              value: category.id,
                              child: Text(
                                category.getDisplayName(_locale),
                              ),
                            ),
                          )
                              .toList(),
                          onChanged: _categoryReadOnly
                              ? null
                              : (value) {
                            setState(() {
                              _selectedCategoryId = value;
                              _errorMessage = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: describeIssue,
                          hintText: describeHint,
                          hintStyle: TextStyle(
                            color: theme.hintColor,
                            fontSize: 13,
                          ),
                          alignLabelWithHint: true,
                          prefixIcon: Icon(
                            Icons.description_outlined,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor:
                          theme.colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          labelStyle: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 5) {
                            return describeIssue;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            submitLabel,
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
              ],

              // Loading
              if (_isSubmitting) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    sendingLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
              ],

              // Success
              if (_isSuccess) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
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
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        requestSent,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        awaiting,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _closeDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
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
              ],

              // Error
              if (!_isSubmitting &&
                  !_isSuccess &&
                  _errorMessage != null &&
                  !_errorMessage!.toLowerCase().contains('service')) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.error.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _errorMessage = null;
                      _isSubmitting = false;
                    }),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.hintColor.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      retryLabel,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}