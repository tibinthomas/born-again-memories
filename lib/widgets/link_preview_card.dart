import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkPreviewCard extends StatelessWidget {
  final String url;
  final String? label;

  const LinkPreviewCard({super.key, required this.url, this.label});

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _iconForUrl() {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host.contains('youtube') || host.contains('youtu.be')) return Icons.play_circle_filled;
    if (host.contains('instagram')) return Icons.camera_alt;
    if (host.contains('photos.google') || host.contains('google')) return Icons.photo_library;
    return Icons.link;
  }

  Color _colorForUrl() {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host.contains('youtube') || host.contains('youtu.be')) return Colors.red;
    if (host.contains('instagram')) return Colors.purple;
    if (host.contains('photos.google') || host.contains('google')) return Colors.blue;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    if (label != null && label!.isNotEmpty) {
      return _LabeledLinkTile(
        label: label!,
        url: url,
        icon: _iconForUrl(),
        iconColor: _colorForUrl(),
        onTap: _open,
      );
    }

    return AnyLinkPreview(
      link: url,
      displayDirection: UIDirection.uiDirectionHorizontal,
      showMultimedia: true,
      bodyMaxLines: 2,
      bodyTextOverflow: TextOverflow.ellipsis,
      titleStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      bodyStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      errorWidget: _LabeledLinkTile(
        url: url,
        icon: _iconForUrl(),
        iconColor: _colorForUrl(),
        onTap: _open,
      ),
      cache: const Duration(hours: 24),
      backgroundColor: Colors.grey.shade100,
      borderRadius: 12.0,
      boxShadow: const [],
      onTap: _open,
    );
  }
}

class _LabeledLinkTile extends StatelessWidget {
  final String url;
  final String? label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _LabeledLinkTile({
    required this.url,
    this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final host = Uri.tryParse(url)?.host ?? url;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null && label!.isNotEmpty)
                    Text(
                      label!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    host,
                    style: TextStyle(
                      fontSize: label != null && label!.isNotEmpty ? 11 : 13,
                      color: label != null && label!.isNotEmpty ? Colors.grey.shade500 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new, size: 15, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
