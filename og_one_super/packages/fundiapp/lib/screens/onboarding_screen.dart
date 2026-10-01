
import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
const OnboardingScreen({super.key});

@override
State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
with SingleTickerProviderStateMixin {
final PageController _pageController = PageController();

late AnimationController _animationController;
late Animation<double> _fadeAnimation;
late Animation<Offset> _slideAnimation;

int _currentPage = 0;

final List<OnboardingItem> _items = const [
OnboardingItem(
title: 'Find a Trusted Fundi',
description:
'Find verified technicians near you and get the help you need, whenever you need it.',
icon: Icons.handyman_rounded,
accentColor: AppTheme.primary,
number: '01',
),
OnboardingItem(
title: 'Connect in Minutes',
description:
'Send your request and connect directly with an available technician around you.',
icon: Icons.bolt_rounded,
accentColor: AppTheme.accent,
number: '02',
),
OnboardingItem(
title: 'Track With Confidence',
description:
'Follow your technician in real-time and enjoy a simple, reliable and trusted service.',
icon: Icons.location_on_rounded,
accentColor: AppTheme.success,
number: '03',
),
];

@override
void initState() {
super.initState();

_animationController = AnimationController(
vsync: this,
duration: const Duration(milliseconds: 600),
);

_fadeAnimation = CurvedAnimation(
parent: _animationController,
curve: Curves.easeOut,
);

_slideAnimation = Tween<Offset>(
begin: const Offset(0, 0.08),
end: Offset.zero,
).animate(
CurvedAnimation(
parent: _animationController,
curve: Curves.easeOutCubic,
),
);

_animationController.forward();
}

@override
void dispose() {
_pageController.dispose();
_animationController.dispose();
super.dispose();
}

void _animateContent() {
_animationController
..reset()
..forward();
}

void _nextPage() {
if (_currentPage == _items.length - 1) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => const LoginScreen(),
),
);
return;
}

_pageController.nextPage(
duration: const Duration(milliseconds: 450),
curve: Curves.easeInOutCubic,
);
}

void _previousPage() {
if (_currentPage == 0) return;

_pageController.previousPage(
duration: const Duration(milliseconds: 450),
curve: Curves.easeInOutCubic,
);
}

void _skip() {
_pageController.animateToPage(
_items.length - 1,
duration: const Duration(milliseconds: 450),
curve: Curves.easeInOutCubic,
);
}

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;

final backgroundColor = isDark
? AppTheme.darkBackground
    : AppTheme.scaffoldLight;

final textColor = isDark
? AppTheme.darkTextPrimary
    : Colors.black87;

final secondaryTextColor = isDark
? AppTheme.darkTextSecondary
    : AppTheme.greyText;

return Scaffold(
backgroundColor: backgroundColor,
body: SafeArea(
child: LayoutBuilder(
builder: (context, constraints) {
final isSmallHeight = constraints.maxHeight < 700;
final horizontalPadding =
constraints.maxWidth < 380 ? 20.0 : 26.0;

return Column(
children: [
_buildHeader(
isDark: isDark,
textColor: textColor,
horizontalPadding: horizontalPadding,
),

Expanded(
child: PageView.builder(
controller: _pageController,
physics: const BouncingScrollPhysics(),
itemCount: _items.length,
onPageChanged: (index) {
setState(() {
_currentPage = index;
});

_animateContent();
},
itemBuilder: (context, index) {
return FadeTransition(
opacity: _fadeAnimation,
child: SlideTransition(
position: _slideAnimation,
child: _OnboardingContent(
item: _items[index],
isDark: isDark,
textColor: textColor,
secondaryTextColor: secondaryTextColor,
compact: isSmallHeight,
),
),
);
},
),
),

_buildBottomSection(
isDark: isDark,
horizontalPadding: horizontalPadding,
),
],
);
},
),
),
);
}

Widget _buildHeader({
required bool isDark,
required Color textColor,
required double horizontalPadding,
}) {
return Padding(
padding: EdgeInsets.fromLTRB(
horizontalPadding,
18,
horizontalPadding,
8,
),
child: Row(
children: [
// Logo
Container(
width: 46,
height: 46,
padding: const EdgeInsets.all(9),
decoration: BoxDecoration(
color: isDark
? AppTheme.darkSurface
    : AppTheme.light,
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: isDark
? AppTheme.darkBorder
    : AppTheme.borderLight,
),
),
child: Image.asset(
'assets/images/nearbyfundi-logov2.png',
fit: BoxFit.contain,
errorBuilder: (_, __, ___) {
return const Icon(
Icons.handyman_rounded,
color: AppTheme.primary,
size: 25,
);
},
),
),

const SizedBox(width: 12),

// Brand
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Nearby Fundi',
style: TextStyle(
color: textColor,
fontSize: 17,
fontWeight: FontWeight.w800,
letterSpacing: -0.3,
),
),
const SizedBox(height: 2),
Text(
'Trusted technicians near you',
style: TextStyle(
color: isDark
? AppTheme.darkTextSecondary
    : AppTheme.greyText,
fontSize: 11.5,
fontWeight: FontWeight.w500,
),
),
],
),
),

if (_currentPage < _items.length - 1)
TextButton(
onPressed: _skip,
style: TextButton.styleFrom(
foregroundColor: isDark
? AppTheme.darkTextSecondary
    : AppTheme.greyText,
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 8,
),
minimumSize: Size.zero,
tapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
child: const Text(
'Skip',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w700,
),
),
),
],
),
);
}

Widget _buildBottomSection({
required bool isDark,
required double horizontalPadding,
}) {
final currentItem = _items[_currentPage];

return Padding(
padding: EdgeInsets.fromLTRB(
horizontalPadding,
8,
horizontalPadding,
22,
),
child: Column(
children: [
// Progress indicators
Row(
children: List.generate(
_items.length,
(index) {
final isActive = index == _currentPage;

return Expanded(
child: AnimatedContainer(
duration: const Duration(milliseconds: 300),
height: 4,
margin: EdgeInsets.only(
right: index == _items.length - 1 ? 0 : 6,
),
decoration: BoxDecoration(
color: isActive
? currentItem.accentColor
    : isDark
? AppTheme.darkBorder
    : AppTheme.borderLight,
borderRadius: BorderRadius.circular(10),
),
),
);
},
),
),

const SizedBox(height: 18),

// Page count
Row(
children: [
Text(
'${_currentPage + 1}',
style: TextStyle(
color: currentItem.accentColor,
fontSize: 13,
fontWeight: FontWeight.w800,
),
),
Text(
' / ${_items.length}',
style: TextStyle(
color: isDark
? AppTheme.darkTextSecondary
    : AppTheme.greyText,
fontSize: 13,
fontWeight: FontWeight.w600,
),
),
],
),

const SizedBox(height: 12),

// Navigation
Row(
children: [
if (_currentPage > 0) ...[
SizedBox(
width: 54,
height: 52,
child: OutlinedButton(
onPressed: _previousPage,
style: OutlinedButton.styleFrom(
padding: EdgeInsets.zero,
foregroundColor: AppTheme.primary,
side: BorderSide(
color: isDark
? AppTheme.darkBorder
    : AppTheme.borderLight,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: const Icon(
Icons.arrow_back_rounded,
size: 20,
),
),
),
const SizedBox(width: 10),
],

Expanded(
child: SizedBox(
height: 52,
child: ElevatedButton(
onPressed: _nextPage,
style: ElevatedButton.styleFrom(
backgroundColor: AppTheme.primary,
foregroundColor: AppTheme.light,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(
_currentPage == _items.length - 1
? 'Get Started'
    : 'Continue',
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w700,
),
),
const SizedBox(width: 8),
const Icon(
Icons.arrow_forward_rounded,
size: 18,
),
],
),
),
),
),
],
),
],
),
);
}
}

class _OnboardingContent extends StatelessWidget {
final OnboardingItem item;
final bool isDark;
final Color textColor;
final Color secondaryTextColor;
final bool compact;

const _OnboardingContent({
required this.item,
required this.isDark,
required this.textColor,
required this.secondaryTextColor,
required this.compact,
});

@override
Widget build(BuildContext context) {
return SingleChildScrollView(
physics: const BouncingScrollPhysics(),
padding: EdgeInsets.symmetric(
horizontal: 24,
vertical: compact ? 10 : 18,
),
child: Column(
children: [
SizedBox(
height: compact ? 225 : 285,
child: _buildIllustration(),
),

SizedBox(height: compact ? 18 : 24),

// Small accent label
Text(
'NEARBY FUNDI',
style: TextStyle(
color: item.accentColor,
fontSize: 10,
fontWeight: FontWeight.w800,
letterSpacing: 1.8,
),
),

const SizedBox(height: 12),

// Heading
ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 430,
),
child: Text(
item.title,
textAlign: TextAlign.center,
style: TextStyle(
color: textColor,
fontSize: compact ? 28 : 32,
height: 1.12,
fontWeight: FontWeight.w800,
letterSpacing: -0.8,
),
),
),

const SizedBox(height: 14),

// Description
ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 440,
),
child: Text(
item.description,
textAlign: TextAlign.center,
style: TextStyle(
color: secondaryTextColor,
fontSize: 14,
height: 1.65,
fontWeight: FontWeight.w500,
),
),
),

SizedBox(height: compact ? 20 : 28),

// Simple feature row
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
_Feature(
icon: Icons.verified_rounded,
label: 'Verified',
color: item.accentColor,
isDark: isDark,
),
const SizedBox(width: 8),
_Feature(
icon: Icons.location_on_rounded,
label: 'Nearby',
color: item.accentColor,
isDark: isDark,
),
const SizedBox(width: 8),
_Feature(
icon: Icons.star_rounded,
label: 'Trusted',
color: item.accentColor,
isDark: isDark,
),
],
),
],
),
);
}

Widget _buildIllustration() {
return Stack(
alignment: Alignment.center,
children: [
// Outer circle
Container(
width: 245,
height: 245,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: item.accentColor.withOpacity(
isDark ? 0.06 : 0.045,
),
),
),

// Middle circle
Container(
width: 190,
height: 190,
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(
color: item.accentColor.withOpacity(
isDark ? 0.18 : 0.13,
),
width: 1,
),
),
),

// Inner circle
Container(
width: 145,
height: 145,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: isDark
? AppTheme.darkSurface
    : AppTheme.light,
border: Border.all(
color: item.accentColor.withOpacity(0.20),
width: 1.5,
),
boxShadow: [
BoxShadow(
color: item.accentColor.withOpacity(
isDark ? 0.16 : 0.10,
),
blurRadius: 28,
spreadRadius: 2,
),
],
),
child: Icon(
item.icon,
size: 58,
color: item.accentColor,
),
),

// Top decoration
Positioned(
top: 26,
right: 54,
child: _SmallDot(
color: item.accentColor,
size: 9,
),
),

// Left decoration
Positioned(
left: 38,
top: 94,
child: _SmallDot(
color: item.accentColor,
size: 6,
),
),

// Bottom decoration
Positioned(
bottom: 26,
left: 58,
child: _SmallDot(
color: item.accentColor,
size: 8,
),
),

// Number
Positioned(
right: 34,
bottom: 25,
child: Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: item.accentColor,
shape: BoxShape.circle,
border: Border.all(
color: isDark
? AppTheme.darkBackground
    : AppTheme.scaffoldLight,
width: 5,
),
),
alignment: Alignment.center,
child: Text(
item.number,
style: const TextStyle(
color: AppTheme.light,
fontSize: 11,
fontWeight: FontWeight.w800,
),
),
),
),
],
);
}
}

class _Feature extends StatelessWidget {
final IconData icon;
final String label;
final Color color;
final bool isDark;

const _Feature({
required this.icon,
required this.label,
required this.color,
required this.isDark,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 7,
),
decoration: BoxDecoration(
color: isDark
? AppTheme.darkSurface
    : AppTheme.light,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: isDark
? AppTheme.darkBorder
    : AppTheme.borderLight,
),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 13,
color: color,
),
const SizedBox(width: 5),
Text(
label,
style: TextStyle(
color: isDark
? AppTheme.darkTextSecondary
    : AppTheme.greyText,
fontSize: 10.5,
fontWeight: FontWeight.w600,
),
),
],
),
);
}
}

class _SmallDot extends StatelessWidget {
final Color color;
final double size;

const _SmallDot({
required this.color,
required this.size,
});

@override
Widget build(BuildContext context) {
return Container(
width: size,
height: size,
decoration: BoxDecoration(
color: color,
shape: BoxShape.circle,
),
);
}
}

class OnboardingItem {
final String title;
final String description;
final IconData icon;
final Color accentColor;
final String number;

const OnboardingItem({
required this.title,
required this.description,
required this.icon,
required this.accentColor,
required this.number,
});
}

