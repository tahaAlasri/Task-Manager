import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// واجهة خدمة تشغيل الأصوات المحيطية للتركيز
abstract class IAmbientAudioService {
  Future<void> playAmbient(String type, {double volume = 0.5});
  Future<void> stopAmbient();
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

/// تنفيذ خدمة الصوت المحيطي المدمجة والمهدئة Offline باستخدام مكتبة المشغل الصوتي
class AmbientAudioService implements IAmbientAudioService {
  AmbientAudioService({AudioPlayer? player}) : _customPlayer = player;

  static final AmbientAudioService instance = AmbientAudioService();

  final AudioPlayer? _customPlayer;
  AudioPlayer? _lazyPlayer;
  String? _currentType;
  double _volume = 0.5;
  bool _isPlaying = false;

  AudioPlayer? get _player {
    if (_customPlayer != null) return _customPlayer;
    if (_lazyPlayer == null) {
      try {
        _lazyPlayer = AudioPlayer();
        _lazyPlayer!.setReleaseMode(ReleaseMode.loop);
      } catch (_) {}
    }
    return _lazyPlayer;
  }

  bool get isPlaying => _isPlaying;
  String? get currentType => _currentType;
  double get volume => _volume;

  @override
  Future<void> playAmbient(String type, {double volume = 0.5}) async {
    _currentType = type;
    _volume = volume.clamp(0.0, 1.0);
    _isPlaying = true;

    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}

    final assetFileName = _mapTypeToFileName(type);
    if (assetFileName == null) {
      await stopAmbient();
      return;
    }

    try {
      final player = _player;
      if (player != null) {
        await player.stop();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(_volume);
        await player.play(AssetSource('audio/$assetFileName'));
      }
    } catch (_) {}
  }

  String? _mapTypeToFileName(String type) {
    switch (type.toLowerCase()) {
      case 'rain':
        return 'rain.mp3';
      case 'waves':
      case 'ocean':
        return 'waves.mp3';
      case 'forest':
      case 'nature':
      case 'birds':
        return 'forest.mp3';
      case 'cafe':
      case 'coffee':
        return 'cafe.mp3';
      default:
        return null;
    }
  }

  @override
  Future<void> stopAmbient() async {
    _isPlaying = false;
    _currentType = null;
    try {
      await _player?.stop();
    } catch (_) {}
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(_volume);
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
  }
}
