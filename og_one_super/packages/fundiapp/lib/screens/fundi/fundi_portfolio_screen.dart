
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
State<FundiPortfolioScreen> createState() =>
_FundiPortfolioScreenState();
}

class _FundiPortfolioScreenState extends State<FundiPortfolioScreen> {
final TextEditingController _filterController =
TextEditingController();

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

List<PortfolioItem> _filteredItems(
List<PortfolioItem> items,
) {
final query = _filterQuery.trim().toLowerCase();

if (query.isEmpty) {
return items;
}

return items.where((item) {
final description =
item.description?.toLowerCase() ?? '';

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
title: Text(
l10n.portfolio,
style: const TextStyle(
color: Colors.white,
fontSize: 19,
fontWeight: FontWeight.w700,
),
),
leading: IconButton(
icon: const Icon(
Icons.arrow_back_ios_new_rounded,
color: Colors.white,
),
onPressed: () {
Navigator.pushReplacementNamed(
context,
AppRoutes.home,
);
},
),
actions: [
IconButton(
icon: const Icon(
Icons.add_rounded,
color: Colors.white,
size: 28,
),
onPressed: () {
_showPortfolioForm(context);
},
),
const SizedBox(width: 4),
],
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
child: _buildPortfolioGrid(
context,
items,
),
),
),
],
),
);
}

// ================================================================
// RESPONSIVE GRID
// ================================================================

Widget _buildPortfolioGrid(
BuildContext context,
List<PortfolioItem> items,
) {
return LayoutBuilder(
builder: (context, constraints) {
final width = constraints.maxWidth;

int columns;

if (width < 600) {
columns = 1;
} else if (width < 950) {
columns = 2;
} else if (width < 1300) {
columns = 3;
} else {
columns = 4;
}

const horizontalPadding = 16.0;
const spacing = 12.0;

final totalSpacing =
spacing * (columns - 1);

final availableWidth =
width -
horizontalPadding * 2 -
totalSpacing;

final cardWidth =
availableWidth / columns;

// Prevent extremely wide cards on very large screens.
if (cardWidth > 480 && columns > 1) {
columns = columns - 1;
}

return GridView.builder(
physics:
const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.fromLTRB(
horizontalPadding,
4,
horizontalPadding,
24,
),
gridDelegate:
SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: columns,
crossAxisSpacing: spacing,
mainAxisSpacing: spacing,
childAspectRatio:
_cardAspectRatio(width),
),
itemCount: items.length,
itemBuilder: (context, index) {
final item = items[index];

return _PortfolioPostCard(
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
);
},
);
},
);
}

double _cardAspectRatio(double width) {
if (width < 400) {
return 0.78;
}

if (width < 600) {
return 0.82;
}

if (width < 1000) {
return 0.84;
}

return 0.86;
}

// ================================================================
// SEARCH BAR
// ================================================================

Widget _buildSearchBar(BuildContext context) {
final l10n = AppLocalizations.of(context)!;

return Padding(
padding: const EdgeInsets.fromLTRB(
16,
12,
16,
8,
),
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 900,
),
child: Container(
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: const Color(0xFFE4E7EC),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.04),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
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
prefixIcon: Icon(
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
border: InputBorder.none,
contentPadding:
const EdgeInsets.symmetric(
horizontal: 16,
vertical: 14,
),
),
onChanged: (value) {
setState(() {
_filterQuery = value;
});
},
),
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
constraints: const BoxConstraints(
maxWidth: 420,
),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: Colors.white,
shape: BoxShape.circle,
border: Border.all(
color: const Color(0xFFE4E7EC),
),
),
child: Icon(
Icons.photo_library_outlined,
size: 48,
color:
AppTheme.primary.withOpacity(0.65),
),
),
const SizedBox(height: 18),
Text(
l10n.noPortfolio,
textAlign: TextAlign.center,
style: const TextStyle(
color: Color(0xFF101828),
fontSize: 18,
fontWeight: FontWeight.w700,
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
const SizedBox(height: 20),
ElevatedButton.icon(
onPressed: () {
_showPortfolioForm(context);
},
icon: const Icon(Icons.add_rounded),
label: Text(l10n.addPortfolio),
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primary,
foregroundColor: Colors.white,
elevation: 0,
padding:
const EdgeInsets.symmetric(
horizontal: 20,
vertical: 13,
),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
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
physics:
const AlwaysScrollableScrollPhysics(),
children: [
SizedBox(
height:
MediaQuery.of(context).size.height * 0.55,
child: Center(
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
const Icon(
Icons.search_off_rounded,
size: 52,
color: Color(0xFF98A2B3),
),
const SizedBox(height: 14),
const Text(
'No results found',
style: TextStyle(
color: Color(0xFF101828),
fontSize: 18,
fontWeight: FontWeight.w700,
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
boundaryMargin:
const EdgeInsets.all(20),
child: Image.network(
ImageUtils.getFullImageUrl(
imageUrl,
),
fit: BoxFit.contain,
errorBuilder: (_, __, ___) {
return Container(
width: 280,
height: 220,
decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(16),
),
child: const Center(
child: Icon(
Icons
    .broken_image_outlined,
size: 56,
color: Color(0xFF98A2B3),
),
),
);
},
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

final descController =
TextEditingController(
text: item?.description ?? '',
);

String? imagePath;

final picker = ImagePicker();
final l10n = AppLocalizations.of(context)!;

showModalBottomSheet(
context: context,
isScrollControlled: true,
useSafeArea: true,
backgroundColor: Colors.white,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(
top: Radius.circular(26),
),
),
builder: (sheetContext) {
return StatefulBuilder(
builder: (
context,
modalSetState,
) {
return Padding(
padding: EdgeInsets.only(
left: 20,
right: 20,
top: 20,
bottom:
MediaQuery.of(context)
    .viewInsets
    .bottom +
20,
),
child: Center(
child: ConstrainedBox(
constraints:
const BoxConstraints(
maxWidth: 700,
),
child: Form(
key: formKey,
child: SingleChildScrollView(
child: Column(
mainAxisSize:
MainAxisSize.min,
crossAxisAlignment:
CrossAxisAlignment
    .stretch,
children: [
// HEADER
Row(
children: [
Container(
padding:
const EdgeInsets
    .all(9),
decoration:
BoxDecoration(
color: AppTheme
    .primary
    .withOpacity(
0.10,
),
borderRadius:
BorderRadius
    .circular(
11,
),
),
child: Icon(
item == null
? Icons
    .add_photo_alternate_outlined
    : Icons
    .edit_outlined,
color:
AppTheme.primary,
size: 22,
),
),
const SizedBox(
width: 12,
),
Expanded(
child: Text(
item == null
? 'Add Portfolio Item'
    : 'Edit Portfolio Item',
style:
const TextStyle(
color: Color(
0xFF101828,
),
fontSize: 19,
fontWeight:
FontWeight
    .w700,
),
),
),
IconButton(
icon: const Icon(
Icons
    .close_rounded,
color: Color(
0xFF667085,
),
),
onPressed: () {
Navigator.pop(
sheetContext,
);
},
),
],
),

const SizedBox(
height: 22,
),

// IMAGE PICKER
GestureDetector(
onTap: () async {
final file =
await picker
    .pickImage(
source:
ImageSource
    .gallery,
imageQuality: 88,
maxWidth: 1600,
);

if (file != null) {
modalSetState(() {
imagePath =
file.path;
});
}
},
child: AspectRatio(
aspectRatio: 16 / 9,
child: Container(
decoration:
BoxDecoration(
color: const Color(
0xFFF2F4F7,
),
borderRadius:
BorderRadius
    .circular(
16,
),
border:
Border.all(
color:
const Color(
0xFFE4E7EC,
),
),
),
clipBehavior:
Clip.antiAlias,
child:
_buildPickerContent(
imagePath,
item,
),
),
),
),

const SizedBox(
height: 20,
),

// DESCRIPTION
TextFormField(
controller:
descController,
maxLines: 5,
minLines: 4,
style:
const TextStyle(
color:
Color(0xFF101828),
fontSize: 15,
height: 1.45,
),
decoration:
_inputDecoration(
l10n.description,
'Tell us about this project...',
),
),

const SizedBox(
height: 24,
),

// BUTTONS
LayoutBuilder(
builder: (
context,
constraints,
) {
if (constraints
    .maxWidth <
420) {
return Column(
crossAxisAlignment:
CrossAxisAlignment
    .stretch,
children: [
CustomButton(
text: item ==
null
? l10n.add
    : l10n.update,
onPressed:
() async {
await _saveItem(
sheetContext,
item,
imagePath,
descController,
);
},
isLoading: context
    .watch<
PortfolioProvider>()
    .isLoading,
),
const SizedBox(
height: 8,
),
TextButton(
onPressed: () {
Navigator.pop(
sheetContext,
);
},
child: Text(
l10n.cancel,
),
),
],
);
}

return Row(
children: [
Expanded(
child:
TextButton(
onPressed: () {
Navigator.pop(
sheetContext,
);
},
child: Text(
l10n.cancel,
),
),
),
const SizedBox(
width: 12,
),
Expanded(
child:
CustomButton(
text: item ==
null
? l10n.add
    : l10n.update,
onPressed:
() async {
await _saveItem(
sheetContext,
item,
imagePath,
descController,
);
},
isLoading: context
    .watch<
PortfolioProvider>()
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

if (item?.image != null &&
item!.image.isNotEmpty) {
return Stack(
fit: StackFit.expand,
children: [
Image.network(
ImageUtils.getFullImageUrl(
item.image,
),
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
padding: const EdgeInsets.all(13),
decoration: BoxDecoration(
color:
AppTheme.primary.withOpacity(0.09),
shape: BoxShape.circle,
),
child: Icon(
Icons.add_photo_alternate_outlined,
size: 34,
color: AppTheme.primary,
),
),
const SizedBox(height: 9),
const Text(
'Tap to select an image',
style: TextStyle(
color: Color(0xFF475467),
fontSize: 14,
fontWeight: FontWeight.w600,
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
color: Colors.black.withOpacity(0.60),
borderRadius:
BorderRadius.circular(20),
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
// INPUT DECORATION
// ================================================================

InputDecoration _inputDecoration(
String label,
String hint,
) {
return InputDecoration(
labelText: label,
hintText: hint,
labelStyle: const TextStyle(
color: Color(0xFF667085),
fontSize: 14,
),
hintStyle: const TextStyle(
color: Color(0xFF98A2B3),
fontSize: 14,
),
filled: true,
fillColor: const Color(0xFFF8F9FA),
contentPadding:
const EdgeInsets.symmetric(
horizontal: 16,
vertical: 15,
),
border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: const BorderSide(
color: Color(0xFFE4E7EC),
),
),
enabledBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: const BorderSide(
color: Color(0xFFE4E7EC),
),
),
focusedBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: BorderSide(
color: AppTheme.primary,
width: 1.5,
),
),
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
content: Text(
'Please select an image',
),
behavior:
SnackBarBehavior.floating,
),
);
return;
}

final provider =
context.read<PortfolioProvider>();

final description =
descController.text.trim();

bool success;

if (item == null) {
final Map<String, dynamic> data = {
'description': description,
};

if (imagePath != null) {
data['image'] = imagePath;
}

success =
await provider.addPortfolio(data);
} else {
final Map<String, dynamic> data = {};

if (imagePath != null) {
data['image'] = imagePath;
}

if (description !=
(item.description ?? '')) {
data['description'] = description;
}

if (data.isEmpty) {
if (sheetContext.mounted) {
Navigator.pop(sheetContext);
}
return;
}

success =
await provider.updatePortfolio(
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
item == null
? l10n.itemAdded
    : l10n.itemUpdated,
),
backgroundColor: AppTheme.primary,
behavior:
SnackBarBehavior.floating,
margin: const EdgeInsets.all(16),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
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

final confirmed =
await showDialog<bool>(
context: context,
builder: (dialogContext) {
return AlertDialog(
backgroundColor: Colors.white,
surfaceTintColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(20),
),
title: Text(
l10n.deletePortfolioItem,
style: const TextStyle(
color: Color(0xFF101828),
fontWeight: FontWeight.w700,
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
Navigator.pop(
dialogContext,
false,
);
},
child: Text(l10n.cancel),
),
ElevatedButton(
onPressed: () {
Navigator.pop(
dialogContext,
true,
);
},
style:
ElevatedButton.styleFrom(
backgroundColor:
AppTheme.error,
foregroundColor:
Colors.white,
elevation: 0,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(11),
),
),
child: Text(l10n.delete),
),
],
);
},
);

if (confirmed != true) return;

final success = await context
    .read<PortfolioProvider>()
    .deletePortfolio(id);

if (!context.mounted) return;

if (success) {
ScaffoldMessenger.of(context)
    .showSnackBar(
SnackBar(
content:
Text(l10n.itemDeleted),
backgroundColor:
AppTheme.success,
behavior:
SnackBarBehavior.floating,
margin: const EdgeInsets.all(16),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
);
}
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
required this.item,
required this.onImageTap,
required this.onEdit,
required this.onDelete,
});

@override
State<_PortfolioPostCard> createState() =>
_PortfolioPostCardState();
}

class _PortfolioPostCardState
extends State<_PortfolioPostCard> {
bool _expanded = false;

String _formatDate(DateTime? dateTime) {
if (dateTime == null) return '';

final difference =
DateTime.now().difference(dateTime);

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

@override
Widget build(BuildContext context) {
final description =
widget.item.description?.trim() ?? '';

final showReadMore =
description.length > 120;

return Container(
decoration: BoxDecoration(
// WHITE CARD
color: Colors.white,
borderRadius:
BorderRadius.circular(14),
border: Border.all(
color: const Color(0xFFE4E7EC),
),
boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(0.045),
blurRadius: 9,
offset: const Offset(0, 3),
),
],
),
clipBehavior: Clip.antiAlias,
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
// ==========================================================
// HEADER
// ==========================================================

Padding(
padding: const EdgeInsets.fromLTRB(
10,
9,
6,
7,
),
child: Row(
children: [
Container(
width: 36,
height: 36,
decoration: BoxDecoration(
color: AppTheme.primary
    .withOpacity(0.10),
shape: BoxShape.circle,
),
child: Icon(
Icons
    .photo_library_outlined,
color: AppTheme.primary,
size: 19,
),
),
const SizedBox(width: 9),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
const Text(
'Portfolio Item',
maxLines: 1,
overflow:
TextOverflow.ellipsis,
style: TextStyle(
color:
Color(0xFF101828),
fontSize: 14,
fontWeight:
FontWeight.w700,
),
),
const SizedBox(height: 2),
Text(
_formatDate(
widget.item.createdAt,
),
maxLines: 1,
overflow:
TextOverflow.ellipsis,
style: const TextStyle(
color:
Color(0xFF98A2B3),
fontSize: 11,
fontWeight:
FontWeight.w500,
),
),
],
),
),
IconButton(
visualDensity:
VisualDensity.compact,
padding: EdgeInsets.zero,
icon: const Icon(
Icons.edit_outlined,
size: 19,
),
color: AppTheme.primary,
onPressed:
widget.onEdit,
),
IconButton(
visualDensity:
VisualDensity.compact,
padding: EdgeInsets.zero,
icon: const Icon(
Icons
    .delete_outline_rounded,
size: 20,
),
color: AppTheme.error,
onPressed:
widget.onDelete,
),
],
),
),

// ==========================================================
// HORIZONTAL IMAGE
// ==========================================================

if (widget.item.image.isNotEmpty)
GestureDetector(
onTap: widget.onImageTap,
child: AspectRatio(
aspectRatio: 16 / 9,
child: Image.network(
ImageUtils.getFullImageUrl(
widget.item.image,
),
width: double.infinity,
fit: BoxFit.cover,
filterQuality:
FilterQuality.medium,
loadingBuilder:
(
context,
child,
progress,
) {
if (progress == null) {
return child;
}

return Container(
color:
const Color(0xFFF2F4F7),
alignment:
Alignment.center,
child:
CircularProgressIndicator(
strokeWidth: 2,
color:
AppTheme.primary,
),
);
},
errorBuilder:
(_, __, ___) {
return Container(
color:
const Color(0xFFF2F4F7),
alignment:
Alignment.center,
child: const Icon(
Icons
    .broken_image_outlined,
size: 44,
color:
Color(0xFF98A2B3),
),
);
},
),
),
),

// ==========================================================
// DESCRIPTION
// ==========================================================

if (description.isNotEmpty)
Padding(
padding:
const EdgeInsets.fromLTRB(
12,
10,
12,
12,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
description,
maxLines:
_expanded ? null : 3,
overflow: _expanded
? TextOverflow.visible
    : TextOverflow.ellipsis,
style: const TextStyle(
color:
Color(0xFF344054),
fontSize: 13,
height: 1.45,
),
),
if (showReadMore)
GestureDetector(
onTap: () {
setState(() {
_expanded =
!_expanded;
});
},
child: Padding(
padding:
const EdgeInsets.only(
top: 5,
),
child: Text(
_expanded
? 'Show less'
    : 'Read more',
style: TextStyle(
color:
AppTheme.primary,
fontSize: 12,
fontWeight:
FontWeight.w700,
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

