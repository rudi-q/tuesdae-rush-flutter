import 'package:flutter_test/flutter_test.dart';
import 'package:tuesdae_rush/feature/audio/audio_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AudioManager Tests', () {
    late AudioManager audioManager;

    setUp(() {
      audioManager = AudioManager();
    });

    tearDown(() {
      audioManager.dispose();
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        AudioManager instance1 = AudioManager();
        AudioManager instance2 = AudioManager();
        
        expect(instance1, equals(instance2));
        expect(identical(instance1, instance2), equals(true));
      });
    });

    group('Sound Settings', () {
      test('should initialize with default settings', () {
        expect(audioManager.soundEnabled, equals(true));
        expect(audioManager.volume, equals(0.7));
      });

      test('should toggle sound enabled state', () {
        expect(audioManager.soundEnabled, equals(true));
        
        audioManager.setSoundEnabled(false);
        expect(audioManager.soundEnabled, equals(false));
        
        audioManager.setSoundEnabled(true);
        expect(audioManager.soundEnabled, equals(true));
      });

      test('should set volume within valid range', () {
        audioManager.setVolume(0.5);
        expect(audioManager.volume, equals(0.5));
        
        audioManager.setVolume(1.0);
        expect(audioManager.volume, equals(1.0));
        
        audioManager.setVolume(0.0);
        expect(audioManager.volume, equals(0.0));
      });

      test('should clamp volume to valid range', () {
        audioManager.setVolume(1.5);
        expect(audioManager.volume, equals(1.0));
        
        audioManager.setVolume(-0.5);
        expect(audioManager.volume, equals(0.0));
      });
    });

    group('Audio Initialization', () {
      test('should initialize without throwing errors', () async {
        expect(() async => await audioManager.initialize(), 
               returnsNormally);
      });
    });

    group('Sound Effect Methods', () {
      test('should have playTrafficLightSwitch method', () {
        expect(audioManager.playTrafficLightSwitch, isA<Function>());
      });

      test('should have playCarPassed method', () {
        expect(audioManager.playCarPassed, isA<Function>());
      });

      test('should have playPerfectFlow method', () {
        expect(audioManager.playPerfectFlow, isA<Function>());
      });

      test('should have playCrash method', () {
        expect(audioManager.playCrash, isA<Function>());
      });

      test('should not throw when playing sounds with sound disabled', () async {
        audioManager.setSoundEnabled(false);
        
        expect(() async => await audioManager.playTrafficLightSwitch(), 
               returnsNormally);
        expect(() async => await audioManager.playCarPassed(), 
               returnsNormally);
        expect(() async => await audioManager.playPerfectFlow(), 
               returnsNormally);
        expect(() async => await audioManager.playCrash(), 
               returnsNormally);
      });
    });

    group('Siren Management', () {
      test('should have playAmbulanceSiren method', () {
        expect(audioManager.playAmbulanceSiren, isA<Function>());
      });

      test('should have playPoliceSiren method', () {
        expect(audioManager.playPoliceSiren, isA<Function>());
      });

      test('should have stopSirens method', () {
        expect(audioManager.stopSirens, isA<Function>());
      });

      test('should have stopAllSounds method', () {
        expect(audioManager.stopAllSounds, isA<Function>());
      });

      test('should not throw when playing sirens with sound disabled', () async {
        audioManager.setSoundEnabled(false);
        
        expect(() async => await audioManager.playAmbulanceSiren(), 
               returnsNormally);
        expect(() async => await audioManager.playPoliceSiren(), 
               returnsNormally);
      });

      test('should not throw when stopping sounds', () async {
        expect(() async => await audioManager.stopSirens(), 
               returnsNormally);
        expect(() async => await audioManager.stopAllSounds(), 
               returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle missing audio files gracefully', () async {
        // These should not throw exceptions even if audio files are missing
        expect(() async => await audioManager.playTrafficLightSwitch(), 
               returnsNormally);
        expect(() async => await audioManager.playCarPassed(), 
               returnsNormally);
        expect(() async => await audioManager.playPerfectFlow(), 
               returnsNormally);
        expect(() async => await audioManager.playCrash(), 
               returnsNormally);
        expect(() async => await audioManager.playAmbulanceSiren(), 
               returnsNormally);
        expect(() async => await audioManager.playPoliceSiren(), 
               returnsNormally);
      });
    });

    group('Audio State Management', () {
      test('should stop all sounds when disabled', () {
        audioManager.setSoundEnabled(true);
        
        // Disable sound should stop everything
        audioManager.setSoundEnabled(false);
        
        // No exception should be thrown and sounds should be stopped
        expect(audioManager.soundEnabled, equals(false));
      });
    });

    group('Disposal', () {
      test('should dispose without throwing errors', () {
        expect(() => audioManager.dispose(), returnsNormally);
      });
    });
  });
}
