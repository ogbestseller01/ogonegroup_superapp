import 'package:flutter/material.dart';

import '../../../config/app_strings.dart';
import '../../../config/app_theme.dart';
import '../../../services/api_service.dart';
import 'static_page_scaffold.dart' show staticAppBar;

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const _typeKeys = ['suggestion', 'bug', 'compliment', 'other'];

  static const _typeIcons = <String, IconData>{
    'suggestion': Icons.lightbulb_outline_rounded,
    'bug': Icons.bug_report_outlined,
    'compliment': Icons.favorite_border_rounded,
    'other': Icons.chat_bubble_outline_rounded,
  };

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();

  String _type = 'suggestion';
  int _rating = 0;
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  String? _emailRule(String? v, String requiredMsg, String invalidMsg) {
    if (v == null || v.trim().isEmpty) return requiredMsg;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : invalidMsg;
  }

  String _typeLabel(AppLocalizations t, String key) {
    switch (key) {
      case 'suggestion':
        return t.suggestion;
      case 'bug':
        return t.bugReport;
      case 'compliment':
        return t.compliment;
      default:
        return t.other;
    }
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);

    final res = await ApiService.instance.sendFeedback({
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'type': _type,
      if (_rating > 0) 'rating': _rating,
      'message': _message.text.trim(),
    });

    if (!mounted) return;
    setState(() => _sending = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor:
          res.success ? AppTheme.primary : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );

    if (res.success) {
      _name.clear();
      _email.clear();
      _message.clear();
      setState(() {
        _rating = 0;
        _type = 'suggestion';
      });
    }
  }

  InputDecoration _decoration(String label, IconData icon, bool isDark) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: isDark ? AppTheme.darkBorder : const Color(0xFFE3E8F1),
      ),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade500),
      prefixIcon: Icon(icon, color: isDark ? Colors.white70 : AppTheme.primary),
      filled: true,
      fillColor: isDark ? AppTheme.darkSurface : Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.t;

    final textStyle = TextStyle(
      color: isDark ? Colors.white : AppTheme.primary,
      fontWeight: FontWeight.w600,
    );
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: isDark ? Colors.white60 : Colors.grey.shade600,
    );

    return Scaffold(
      backgroundColor:
      isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FC),
      appBar: staticAppBar(t.sendFeedback),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.helpUsImprove,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.helpUsImproveSub,
                  style: TextStyle(
                    height: 1.4,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 22),
                Text(t.feedbackTypeLabel, style: labelStyle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _typeKeys.map((key) {
                    final selected = _type == key;
                    return ChoiceChip(
                      label: Text(_typeLabel(t, key)),
                      avatar: Icon(
                        _typeIcons[key],
                        size: 17,
                        color: selected
                            ? AppTheme.secondary
                            : (isDark ? Colors.white70 : AppTheme.primary),
                      ),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _type = key),
                      selectedColor: AppTheme.primary,
                      backgroundColor:
                      isDark ? AppTheme.darkSurface : Colors.white,
                      side: BorderSide(
                        color: selected
                            ? AppTheme.primary
                            : (isDark
                            ? AppTheme.darkBorder
                            : const Color(0xFFE3E8F1)),
                      ),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppTheme.primary),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),
                Text(t.rateAppLabel, style: labelStyle),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      tooltip: '$star',
                      padding: const EdgeInsets.only(right: 6),
                      constraints: const BoxConstraints(),
                      iconSize: 38,
                      onPressed: () => setState(
                            () => _rating = _rating == star ? 0 : star,
                      ),
                      icon: Icon(
                        star <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: star <= _rating
                            ? AppTheme.secondary
                            : (isDark ? Colors.white30 : Colors.grey.shade400),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 18),
                TextFormField(
                  controller: _name,
                  style: textStyle,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => _required(v, t.required),
                  decoration:
                  _decoration(t.fullName, Icons.person_rounded, isDark),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  style: textStyle,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      _emailRule(v, t.required, t.validEmail),
                  decoration:
                  _decoration(t.email, Icons.email_rounded, isDark),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _message,
                  style: textStyle,
                  minLines: 5,
                  maxLines: 8,
                  validator: (v) => _required(v, t.required),
                  decoration: _decoration(
                    t.yourFeedback,
                    Icons.edit_note_rounded,
                    isDark,
                  ).copyWith(alignLabelWithHint: true),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _sending ? null : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      t.sendFeedbackBtn,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
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
}