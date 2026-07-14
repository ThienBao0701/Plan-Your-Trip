import 'dart:ui';
import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';

class BubbleBackground extends StatelessWidget {
  final Widget child;
  const BubbleBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                Color(0xFFF8FBFF),
                Color(0xFFEAF4FF),
                Color(0xFFFFF3EA)
              ])),
          child: SizedBox.expand()),
      const Positioned(
          top: -90,
          left: -80,
          child: _Bubble(size: 240, color: AppColors.aqua)),
      const Positioned(
          top: 140,
          right: -90,
          child: _Bubble(size: 220, color: AppColors.violet)),
      const Positioned(
          bottom: -70,
          left: 20,
          child: _Bubble(size: 260, color: AppColors.coral)),
      child,
    ]);
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final Color color;
  const _Bubble({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
      child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: color.withValues(alpha: .25))));
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  const GlassCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(AppSpacing.md),
      this.radius = AppSpacing.radius,
      this.onTap});
  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: .72)),
            boxShadow: [
              BoxShadow(
                  color: AppColors.ocean.withValues(alpha: .08),
                  blurRadius: 30,
                  offset: const Offset(0, 18))
            ],
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return content;
    return Material(
        color: Colors.transparent,
        child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: onTap,
            child: content));
  }
}

class GlassButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  const GlassButton({super.key, required this.text, this.icon, this.onPressed});
  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.auto_awesome_rounded),
        label: Text(text),
        style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: AppColors.midnight,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24))),
      );
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  const GlassTextField(
      {super.key,
      required this.controller,
      required this.hint,
      required this.icon,
      this.obscure = false,
      this.keyboardType});
  @override
  Widget build(BuildContext context) => TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white.withValues(alpha: .70)));
}

class GlassSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  const GlassSearchBar({super.key, required this.hint, this.onTap});
  @override
  Widget build(BuildContext context) => GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: 24,
      onTap: onTap,
      child: Row(children: [
        const Icon(Icons.search_rounded, color: AppColors.ocean),
        const SizedBox(width: 10),
        Expanded(
            child: Text(hint, style: Theme.of(context).textTheme.bodyMedium)),
        const Icon(Icons.tune_rounded, color: AppColors.slate)
      ]));
}

class PremiumLoading extends StatelessWidget {
  const PremiumLoading({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class PremiumErrorState extends StatelessWidget {
  final String message;
  const PremiumErrorState(this.message, {super.key});
  @override
  Widget build(BuildContext context) =>
      Center(child: GlassCard(child: Text(message)));
}

class PremiumEmptyState extends StatelessWidget {
  final String message;
  const PremiumEmptyState(this.message, {super.key});
  @override
  Widget build(BuildContext context) =>
      Center(child: GlassCard(child: Text(message)));
}

class PremiumScaffold extends StatelessWidget {
  final Widget body;
  final int index;
  final ValueChanged<int>? onNav;
  const PremiumScaffold(
      {super.key, required this.body, this.index = 0, this.onNav});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: BubbleBackground(child: SafeArea(child: body)),
        bottomNavigationBar:
            GlassBottomNavigationBar(currentIndex: index, onTap: onNav),
      );
}

class GlassBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  const GlassBottomNavigationBar(
      {super.key, required this.currentIndex, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            radius: 30,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _item(context, 0, Icons.home_rounded, 'Home'),
                  _item(context, 1, Icons.place_rounded, 'Places'),
                  _item(context, 2, Icons.map_rounded, 'Trips'),
                  _item(context, 3, Icons.receipt_long_rounded, 'Budget'),
                  _item(context, 4, Icons.person_rounded, 'Profile'),
                ])),
      );
  Widget _item(BuildContext context, int i, IconData icon, String label) {
    final active = i == currentIndex;
    return InkWell(
        onTap: () => onTap?.call(i),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: active ? AppColors.ocean : AppColors.slate),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      color: active ? AppColors.ocean : AppColors.slate))
            ])));
  }
}
