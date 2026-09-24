import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// خدمة إدارة المرفقات والصور وحفظها محلياً في مجلد التطبيق
class AttachmentService {
  AttachmentService._();
  static final AttachmentService instance = AttachmentService._();

  final ImagePicker _picker = ImagePicker();

  /// الحصول على مجلد حفظ المرفقات المحلي الخاص بالتطبيق
  Future<Directory> _getAttachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/task_attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  /// التقاط صورة عبر الكاميرا وحفظها محلياً
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (photo == null) return null;
      return await _saveFileLocally(photo);
    } catch (_) {
      return null;
    }
  }

  /// اختيار صورة من معرض الصور وحفظها محلياً
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (image == null) return null;
      return await _saveFileLocally(image);
    } catch (_) {
      return null;
    }
  }

  /// نسخ الملف إلى مجلد التطبيق الدائم وإرجاع مساره
  Future<String> _saveFileLocally(XFile file) async {
    final dir = await _getAttachmentsDirectory();
    final fileExt = file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final fileName = 'att_${const Uuid().v4().substring(0, 8)}.$fileExt';
    final localPath = '${dir.path}/$fileName';

    final savedFile = await File(file.path).copy(localPath);
    return savedFile.path;
  }

  /// حذف مرفق من وحدة التخزين المحلية
  Future<bool> deleteAttachment(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
