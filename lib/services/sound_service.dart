import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _isSoundEnabled = true;
  static const String _soundKey = 'sound_enabled';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool(_soundKey) ?? true;
  }

  void playTapSound() {
    if (_isSoundEnabled) {
      HapticFeedback.selectionClick();  // 使用系统自带的触感反馈
      SystemSound.play(SystemSoundType.click);  // 使用系统自带的点击音效
    }
  }

  bool get isSoundEnabled => _isSoundEnabled;

  Future<void> toggleSound() async {
    _isSoundEnabled = !_isSoundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, _isSoundEnabled);
  }
} 