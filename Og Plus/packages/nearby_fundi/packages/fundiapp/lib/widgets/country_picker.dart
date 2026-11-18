// lib/widgets/country_picker.dart
import 'package:flutter/material.dart';
import '../models/country.dart';

// ============================================================
//  FLAG HELPERS
// ============================================================
// Note: Your actual files are named 'tzflug.png' and 'englishflug.png'
String? _getFlagAssetPath(String countryName) {
  switch (countryName.toLowerCase()) {
    case 'tanzania':
      return 'assets/images/tzflug.png';
    case 'english':
    case 'united kingdom':
      return 'assets/images/englishflug.png';
    default:
      return null; // Fallback to emoji if no PNG is found
  }
}

Widget _buildFlagWidget(String name, String emoji, double height) {
  final assetPath = _getFlagAssetPath(name);
  if (assetPath != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.asset(
        assetPath,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // If the image fails to load, fallback to the emoji
          return Text(emoji, style: TextStyle(fontSize: height));
        },
      ),
    );
  }
  return Text(emoji, style: TextStyle(fontSize: height));
}

class CountryPicker extends StatefulWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onChanged;
  final List<Country> countries;

  const CountryPicker({
    super.key,
    required this.selectedCountry,
    required this.onChanged,
    required this.countries,
  });

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  late TextEditingController _searchController;
  List<Country> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = widget.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search country...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _filtered = widget.countries
                            .where((c) =>
                        c.name.toLowerCase().contains(value.toLowerCase()) ||
                            c.dialCode.contains(value))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final country = _filtered[index];
                        return ListTile(
                          // FIXED: Now uses the PNG flag helper
                          leading: _buildFlagWidget(country.name, country.flag, 28),
                          title: Text(country.name),
                          trailing: Text(country.dialCode),
                          onTap: () {
                            widget.onChanged(country);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _showPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIXED: Now uses the PNG flag helper
            _buildFlagWidget(widget.selectedCountry.name, widget.selectedCountry.flag, 24),
            const SizedBox(width: 8),
            Text(
              widget.selectedCountry.dialCode,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}