import 'dart:io';
import 'package:flutter/material.dart';

/// عارض صور بملء الشاشة مع إمكانية التكبير والتحريك (Pinch to Zoom)
class ImageViewerDialog extends StatelessWidget {
  final String imagePath;
  final String? title;

  const ImageViewerDialog({
    super.key,
    required this.imagePath,
    this.title,
  });

  static void show(BuildContext context, String imagePath, {String? title}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => ImageViewerDialog(imagePath: imagePath, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final exists = file.existsSync();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // عارض الصورة التفاعلي
          Center(
            child: exists
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'تعذر العثور على الملف في الجهاز',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
          ),

          // شريط العنوان وزر الإغلاق
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title ?? 'معاينة المرفق',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
