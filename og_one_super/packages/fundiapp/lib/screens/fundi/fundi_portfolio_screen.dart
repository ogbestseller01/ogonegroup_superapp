import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/portfolio.dart';
import '../../providers/portfolio_provider.dart';
import '../../utils/image_utils.dart';
import '../../widgets/custom_button.dart';

const double _maxCardWidth = 640;

/// Accent used for the avatar ring. Swap for your AppTheme accent if you have one.
const Color _gold = Color(0xFFF2B93B);

OutlineInputBorder _pill([Color c = Colors.transparent]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(24),
  borderSide: BorderSide(color: c),
);

OutlineInputBorder _thin(Color c, [double w = 1]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(14),
  borderSide: BorderSide(color: c, width: w),
);

class FundiPortfolioScreen extends StatefulWidget {
  const FundiPortfolioScreen({super.key});

  @override
  State<FundiPortfolioScreen> createState() => _FundiPortfolioScreenState();
}

class _FundiPortfolioScreenState extends State<FundiPortfolioScreen> {
  final TextEditingController _filterController = TextEditingController();

  String _filterQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<PortfolioProvider>().loadPortfolio();
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<PortfolioItem> _filteredItems(List<PortfolioItem> items) {
    final query = _filterQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return items;
    }

    return items.where((item) {
      final description = item.description?.toLowerCase() ?? '';

      return description.contains(query);
    }).toList();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    final l10n = AppLocalizations.of(context)!;

    final items = _filteredItems(provider.items);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Row(
          children: [
            _AppBarButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.home,
                );
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.portfolio,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _AppBarButton(
              icon: Icons.add_rounded,
              onTap: () {
                _showPortfolioForm(context);
              },
            ),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : provider.items.isEmpty
          ? _buildEmptyState(context)
          : Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: items.isEmpty
                ? _buildNoResults(context)
                : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () {
                return context
                    .read<PortfolioProvider>()
                    .loadPortfolio();
              },
              child: _buildPortfolioList(context, items),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LIST (cards size to their content, no empty space)
  // ================================================================

  Widget _buildPortfolioList(
      BuildContext context,
      List<PortfolioItem> items,
      ) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxCardWidth),
            child: _PortfolioPostCard(
              key: ValueKey(item.id),
              item: item,
              onImageTap: () {
                _showImageDialog(
                  context,
                  item.image,
                );
              },
              onEdit: () {
                _showPortfolioForm(
                  context,
                  item: item,
                );
              },
              onDelete: () {
                _deleteItem(
                  context,
                  item.id,
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ================================================================
  // SEARCH BAR
  // ================================================================

  Widget _buildSearchBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxCardWidth),
          child: TextField(
            controller: _filterController,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: l10n.filterByDescription,
              hintStyle: const TextStyle(
                color: Color(0xFF98A2B3),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.primary,
              ),
              suffixIcon: _filterQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  color: Color(0xFF667085),
                ),
                onPressed: () {
                  _filterController.clear();

                  setState(() {
                    _filterQuery = '';
                  });
                },
              )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: _pill(),
              enabledBorder: _pill(),
              focusedBorder: _pill(AppTheme.primary.withValues(alpha: 0.35)),
            ),
            onChanged: (value) {
              setState(() {
                _filterQuery = value;
              });
            },
          ),
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 44,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.noPortfolio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your completed work to showcase your experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  _showPortfolioForm(context);
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addPortfolio),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // NO SEARCH RESULTS
  // ================================================================

  Widget _buildNoResults(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 38,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No results found',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Try a different description.',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // IMAGE PREVIEW
  // ================================================================

  void _showImageDialog(
      BuildContext context,
      String imageUrl,
      ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      ImageUtils.getFullImageUrl(imageUrl),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          width: 280,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 56,
                              color: Color(0xFF98A2B3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // ADD / EDIT PORTFOLIO
  // ================================================================

  void _showPortfolioForm(
      BuildContext context, {
        PortfolioItem? item,
      }) {
    final formKey = GlobalKey<FormState>();

    final descController = TextEditingController(
      text: item?.description ?? '',
    );

    String? imagePath;

    final picker = ImagePicker();
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 4,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // HEADER
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  item == null
                                      ? Icons.add_photo_alternate_outlined
                                      : Icons.edit_outlined,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item == null
                                      ? 'Add Portfolio Item'
                                      : 'Edit Portfolio Item',
                                  style: const TextStyle(
                                    color: Color(0xFF101828),
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF667085),
                                ),
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // IMAGE PICKER
                          GestureDetector(
                            onTap: () async {
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 88,
                                maxWidth: 1600,
                              );

                              if (file != null) {
                                modalSetState(() {
                                  imagePath = file.path;
                                });
                              }
                            },
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFD0D5DD),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildPickerContent(
                                  imagePath,
                                  item,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // DESCRIPTION
                          TextFormField(
                            controller: descController,
                            maxLines: 5,
                            minLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              color: Color(0xFF101828),
                              fontSize: 15,
                              height: 1.45,
                            ),
                            decoration: _inputDecoration(
                              l10n.description,
                              'Tell us about this project...',
                            ),
                          ),

                          const SizedBox(height: 24),

                          // BUTTONS
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cancelStyle = OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(
                                  color: Color(0xFFD0D5DD),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              );

                              if (constraints.maxWidth < 420) {
                                return Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    CustomButton(
                                      text: item == null
                                          ? l10n.add
                                          : l10n.update,
                                      onPressed: () async {
                                        await _saveItem(
                                          sheetContext,
                                          item,
                                          imagePath,
                                          descController,
                                        );
                                      },
                                      isLoading: context
                                          .watch<PortfolioProvider>()
                                          .isLoading,
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton(
                                      style: cancelStyle,
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                      },
                                      child: Text(l10n.cancel),
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: cancelStyle,
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                      },
                                      child: Text(l10n.cancel),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: CustomButton(
                                      text: item == null
                                          ? l10n.add
                                          : l10n.update,
                                      onPressed: () async {
                                        await _saveItem(
                                          sheetContext,
                                          item,
                                          imagePath,
                                          descController,
                                        );
                                      },
                                      isLoading: context
                                          .watch<PortfolioProvider>()
                                          .isLoading,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      descController.dispose();
    });
  }

  // ================================================================
  // PICKER CONTENT
  // ================================================================

  Widget _buildPickerContent(
      String? imagePath,
      PortfolioItem? item,
      ) {
    if (imagePath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return _brokenImage();
            },
          ),
          _changeLabel(),
        ],
      );
    }

    if (item?.image != null && item!.image.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            ImageUtils.getFullImageUrl(item.image),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return _brokenImage();
            },
          ),
          _changeLabel(),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 34,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tap to select an image',
          style: TextStyle(
            color: Color(0xFF475467),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Use a clear image of your completed work',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF98A2B3),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _changeLabel() {
    return Positioned(
      right: 12,
      bottom: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              color: Colors.white,
              size: 15,
            ),
            SizedBox(width: 5),
            Text(
              'Change',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brokenImage() {
    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: Color(0xFF98A2B3),
      ),
    );
  }

  // ================================================================
  // INPUT DECORATION (thin border by default)
  // ================================================================

  InputDecoration _inputDecoration(
      String label,
      String hint,
      ) {
    const base = Color(0xFFD0D5DD);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      labelStyle: const TextStyle(
        color: Color(0xFF667085),
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF98A2B3),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: _thin(base),
      enabledBorder: _thin(base),
      focusedBorder: _thin(AppTheme.primary, 1.5),
      errorBorder: _thin(AppTheme.error),
      focusedErrorBorder: _thin(AppTheme.error, 1.5),
    );
  }

  // ================================================================
  // SAVE ITEM
  // ================================================================

  Future<void> _saveItem(
      BuildContext sheetContext,
      PortfolioItem? item,
      String? imagePath,
      TextEditingController descController,
      ) async {
    final l10n = AppLocalizations.of(context)!;

    if (item == null && imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = context.read<PortfolioProvider>();

    final description = descController.text.trim();

    bool success;

    if (item == null) {
      final Map<String, dynamic> data = {
        'description': description,
      };

      if (imagePath != null) {
        data['image'] = imagePath;
      }

      success = await provider.addPortfolio(data);
    } else {
      final Map<String, dynamic> data = {};

      if (imagePath != null) {
        data['image'] = imagePath;
      }

      if (description != (item.description ?? '')) {
        data['description'] = description;
      }

      if (data.isEmpty) {
        if (sheetContext.mounted) {
          Navigator.pop(sheetContext);
        }
        return;
      }

      success = await provider.updatePortfolio(
        item.id,
        data,
      );
    }

    if (!sheetContext.mounted) return;

    Navigator.pop(sheetContext);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null ? l10n.itemAdded : l10n.itemUpdated,
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ================================================================
  // DELETE
  // ================================================================

  Future<void> _deleteItem(
      BuildContext context,
      int id,
      ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            l10n.deletePortfolioItem,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            l10n.areYouSure,
            style: const TextStyle(
              color: Color(0xFF667085),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success =
    await context.read<PortfolioProvider>().deletePortfolio(id);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.itemDeleted),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

// ==================================================================
// APP BAR BUTTON
// ==================================================================

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ==================================================================
// PORTFOLIO CARD
// ==================================================================

class _PortfolioPostCard extends StatefulWidget {
  final PortfolioItem item;
  final VoidCallback onImageTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PortfolioPostCard({
    super.key,
    required this.item,
    required this.onImageTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PortfolioPostCard> createState() => _PortfolioPostCardState();
}

class _PortfolioPostCardState extends State<_PortfolioPostCard> {
  bool _expanded = false;

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';

    final difference = DateTime.now().difference(dateTime);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    }

    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    }

    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }

    return 'Just now';
  }

  Widget _tonalAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.item.description?.trim() ?? '';

    final showReadMore = description.length > 120;
    final date = _formatDate(widget.item.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // HEADER
          // ==========================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold, width: 2),
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Portfolio Item',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: Color(0xFF98A2B3),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                _tonalAction(
                  icon: Icons.edit_outlined,
                  color: AppTheme.primary,
                  onTap: widget.onEdit,
                ),
                const SizedBox(width: 8),
                _tonalAction(
                  icon: Icons.delete_outline_rounded,
                  color: AppTheme.error,
                  onTap: widget.onDelete,
                ),
              ],
            ),
          ),

          // ==========================================================
          // IMAGE (inset, rounded)
          // ==========================================================

          if (widget.item.image.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: GestureDetector(
                  onTap: widget.onImageTap,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      ImageUtils.getFullImageUrl(widget.item.image),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) {
                          return child;
                        }

                        return Container(
                          color: const Color(0xFFF2F4F7),
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: const Color(0xFFF2F4F7),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 44,
                            color: Color(0xFF98A2B3),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

          // ==========================================================
          // DESCRIPTION
          // ==========================================================

          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: GestureDetector(
                onTap: showReadMore
                    ? () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: description),
                        if (showReadMore)
                          TextSpan(
                            text: _expanded ? '  Show less' : '  Read more',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    maxLines: _expanded ? null : 3,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF344054),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }
}