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

class FundiPortfolioScreen extends StatefulWidget {
  const FundiPortfolioScreen({super.key});

  @override
  State<FundiPortfolioScreen> createState() => _FundiPortfolioScreenState();
}

class _FundiPortfolioScreenState extends State<FundiPortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PortfolioProvider>().loadPortfolio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        title: Row(
          children: [
            _AppBarButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'My Portfolio',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            _AppBarButton(
              icon: Icons.add_rounded,
              onTap: () => _showUploadSheet(context),
            ),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.items.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => context.read<PortfolioProvider>().loadPortfolio(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: provider.items.length,
          itemBuilder: (context, index) {
            final item = provider.items[index];
            return _PortfolioFeedCard(
              item: item,
              onEdit: () => _showEditSheet(context, item),
              onDelete: () => _deleteItem(context, item.id),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 64, color: AppTheme.primary),
          const SizedBox(height: 16),
          const Text('No Posts Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Upload photos of your work to showcase your skills.'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showUploadSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Post'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CREATE POST
  // ================================================================
  void _showUploadSheet(BuildContext context) {
    final picker = ImagePicker();
    List<File> selectedImages = [];
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 4,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('New Portfolio Post', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  if (selectedImages.isNotEmpty)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) => Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(selectedImages[index], fit: BoxFit.cover)),
                            Positioned(
                              top: 4, right: 4,
                              child: GestureDetector(
                                onTap: () => modalSetState(() => selectedImages.removeAt(index)),
                                child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () async {
                      final files = await picker.pickMultiImage(imageQuality: 85);
                      if (files.isNotEmpty) {
                        modalSetState(() => selectedImages.addAll(files.map((e) => File(e.path))));
                      }
                    },
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFD0D5DD))),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppTheme.primary),
                          SizedBox(height: 8),
                          Text('Tap to select images', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Post',
                    isLoading: isUploading,
                    onPressed: selectedImages.isEmpty || isUploading ? null : () async {
                      modalSetState(() => isUploading = true);
                      final paths = selectedImages.map((f) => f.path).toList();
                      await context.read<PortfolioProvider>().addPortfolio(paths);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================================================================
  // EDIT POST (ADD / REMOVE IMAGES)
  // ================================================================
  void _showEditSheet(BuildContext context, PortfolioItem item) {
    final picker = ImagePicker();
    List<File> newImages = [];
    List<PortfolioImage> existingImages = List.from(item.images);
    List<int> deletedImageIds = [];
    bool isUpdating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 4,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Edit Post', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),

                  // Image Grid
                  if (existingImages.isNotEmpty || newImages.isNotEmpty)
                    Container(
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                        itemCount: existingImages.length + newImages.length,
                        itemBuilder: (context, index) {
                          // Render existing images
                          if (index < existingImages.length) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(ImageUtils.getFullImageUrl(existingImages[index].url), fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4, right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      modalSetState(() {
                                        deletedImageIds.add(existingImages[index].id);
                                        existingImages.removeAt(index);
                                      });
                                    },
                                    child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.delete, size: 16, color: Colors.white)),
                                  ),
                                ),
                              ],
                            );
                          }
                          // Render new local images
                          final newIndex = index - existingImages.length;
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(newImages[newIndex], fit: BoxFit.cover)),
                              Positioned(
                                top: 4, right: 4,
                                child: GestureDetector(
                                  onTap: () => modalSetState(() => newImages.removeAt(newIndex)),
                                  child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  GestureDetector(
                    onTap: () async {
                      final files = await picker.pickMultiImage(imageQuality: 85);
                      if (files.isNotEmpty) {
                        modalSetState(() => newImages.addAll(files.map((e) => File(e.path))));
                      }
                    },
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFD0D5DD))),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary),
                          Text('Add more images', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Save Changes',
                    isLoading: isUpdating,
                    onPressed: isUpdating ? null : () async {
                      modalSetState(() => isUpdating = true);
                      final paths = newImages.map((f) => f.path).toList();

                      await context.read<PortfolioProvider>().updatePortfolio(
                        item.id,
                        newImagePaths: paths,
                        deleteImageIds: deletedImageIds,
                      );

                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteItem(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Post?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to remove this entire post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<PortfolioProvider>().deletePortfolio(id);
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
          width: 42, height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ==================================================================
// PORTFOLIO CARD WITH EDIT MENU
// ==================================================================
class _PortfolioFeedCard extends StatefulWidget {
  final PortfolioItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PortfolioFeedCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PortfolioFeedCard> createState() => _PortfolioFeedCardState();
}

class _PortfolioFeedCardState extends State<_PortfolioFeedCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.item.images;
    final hasMultiple = images.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header with 3-dot menu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFEAF1FB),
                  child: Icon(Icons.person, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('My Portfolio', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                  onSelected: (v) {
                    if (v == 'edit') widget.onEdit();
                    if (v == 'delete') widget.onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Images', style: TextStyle(color: AppTheme.primary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          SizedBox(width: 8),
                          Text('Delete Post', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Image Carousel
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      ImageUtils.getFullImageUrl(images[index].url),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(color: Colors.grey[100], child: const Center(child: CircularProgressIndicator()));
                      },
                    );
                  },
                ),

                // Dots indicator
                if (hasMultiple)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 8 : 6,
                          height: _currentPage == index ? 8 : 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index ? Colors.white : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}