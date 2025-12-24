import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.url,
    this.radius = 20,
    this.name,
    this.backgroundColor,
    this.icon,
  });

  final String? url;
  final double radius;
  final String? name;
  final Color? backgroundColor;
  final IconData? icon;

  bool get _hasValidUrl {
    if (url == null) return false;
    final trimmed = url!.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = _buildPlaceholder(context);
    if (!_hasValidUrl) {
      return placeholder;
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!.trim(),
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final bgColor =
        backgroundColor ?? Theme.of(context).primaryColor.withValues(alpha: 0.1);
    final trimmedName = name?.trim() ?? '';
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: initial != null
          ? Text(
              initial,
              style: TextStyle(fontSize: radius * 0.9),
            )
          : Icon(
              icon ?? Icons.person,
              size: radius,
              color: Theme.of(context).primaryColor,
            ),
    );
  }
}
