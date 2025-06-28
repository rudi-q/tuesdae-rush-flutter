import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _soundEffectPlayer = AudioPlayer();
  final AudioPlayer _sirenPlayer = AudioPlayer();
  
  bool _soundEnabled = true;
  double _volume = 0.7;

  bool get soundEnabled => _soundEnabled;
  double get volume => _volume;

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    if (!enabled) {
      stopAllSounds();
    }
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _soundEffectPlayer.setVolume(_volume);
    _sirenPlayer.setVolume(_volume * 0.6); // Sirens slightly quieter
  }

  Future<void> initialize() async {
    await _soundEffectPlayer.setVolume(_volume);
    await _sirenPlayer.setVolume(_volume * 0.6);
  }

  // Sound effects
  Future<void> playTrafficLightSwitch() async {
    if (!_soundEnabled) return;
    try {
      await _soundEffectPlayer.play(AssetSource('audio/light_switch_click.mp3'));
    } catch (e) {
      debugPrint('Error playing traffic light sound: $e');
    }
  }

  Future<void> playCarPassed() async {
    if (!_soundEnabled) return;
    try {
      await _soundEffectPlayer.play(AssetSource('audio/success_car_passed.mp3'));
    } catch (e) {
      debugPrint('Error playing car passed sound: $e');
    }
  }

  Future<void> playPerfectFlow() async {
    if (!_soundEnabled) return;
    try {
      await _soundEffectPlayer.play(AssetSource('audio/success_perfect_flow.mp3'));
    } catch (e) {
      debugPrint('Error playing perfect flow sound: $e');
    }
  }

  Future<void> playCrash() async {
    if (!_soundEnabled) return;
    try {
      await _soundEffectPlayer.play(AssetSource('audio/crash_minor_collision.mp3'));
    } catch (e) {
      debugPrint('Error playing crash sound: $e');
    }
  }

  // Continuous sounds (sirens)
  Future<void> playAmbulanceSiren() async {
    if (!_soundEnabled) return;
    try {
      await _sirenPlayer.play(AssetSource('audio/car_ambulance_siren.mp3'));
      await _sirenPlayer.setPlaybackRate(1.0);
    } catch (e) {
      debugPrint('Error playing ambulance siren: $e');
    }
  }

  Future<void> playPoliceSiren() async {
    if (!_soundEnabled) return;
    try {
      await _sirenPlayer.play(AssetSource('audio/car_police_siren.mp3'));
      await _sirenPlayer.setPlaybackRate(1.0);
    } catch (e) {
      debugPrint('Error playing police siren: $e');
    }
  }

  Future<void> stopSirens() async {
    try {
      await _sirenPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping sirens: $e');
    }
  }

  Future<void> stopAllSounds() async {
    try {
      await _soundEffectPlayer.stop();
      await _sirenPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping all sounds: $e');
    }
  }

  void dispose() {
    _soundEffectPlayer.dispose();
    _sirenPlayer.dispose();
  }
}
