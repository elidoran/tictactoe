import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:tictactoe/src/audio/audio_system.dart';
import 'package:tictactoe/src/settings/persistence/settings_persistence.dart';

class Settings extends ChangeNotifier {
  bool _muted = false;

  final SettingsPersistence _persistence;

  AudioSystem? _audioSystem;

  bool _soundsOn = false;

  bool _musicOn = false;

  Settings({required SettingsPersistence persistence})
      : _persistence = persistence;

  bool get musicOn => _musicOn;

  String get playerName => _playerName;

  String _playerName = 'Player';

  /// Whether or not the sound is on at all. This overrides both music
  /// and sound.
  bool get muted => _muted;

  bool get soundsOn => _soundsOn;

  void attachAudioSystem(AudioSystem audioSystem) {
    if (audioSystem == _audioSystem) {
      return;
    }
    _audioSystem = audioSystem;
    if (!_muted && _musicOn) {
      _audioSystem!.startMusic();
    }
  }

  Future<void> loadStateFromPersistence() async {
    await Future.wait([
      /// The sound starts on (`true`) on every device target except for the web.
      /// On the web, sound can only start after user interaction.
      _persistence
          .getMuted(defaultValue: kIsWeb)
          .then((value) => _muted = value),
      _persistence.getSoundsOn().then((value) => _soundsOn = value),
      _persistence.getMusicOn().then((value) => _musicOn = value),
      _persistence.getPlayerName().then((value) => _playerName = value),
    ]);
    if (_muted) {
      _audioSystem?.stopAllSound();
    } else {
      if (_musicOn) {
        _audioSystem?.resumeMusic();
      }
    }
    notifyListeners();
  }

  void toggleMusicOn() {
    _musicOn = !_musicOn;
    if (_musicOn) {
      if (!_muted) {
        _audioSystem?.resumeMusic();
      }
    } else {
      _audioSystem?.stopMusic();
    }
    notifyListeners();
    _persistence.saveMusicOn(_musicOn);
  }

  void setPlayerName(String name) {
    _playerName = name;
    notifyListeners();
    _persistence.savePlayerName(_playerName);
  }

  void toggleMuted() {
    _muted = !_muted;
    if (_muted) {
      _audioSystem?.stopAllSound();
    } else {
      if (_musicOn) {
        _audioSystem?.resumeMusic();
      }
    }
    notifyListeners();
    _persistence.saveMute(_muted);
  }

  void toggleSoundsOn() {
    _soundsOn = !_soundsOn;
    notifyListeners();
    _persistence.saveSoundsOn(_soundsOn);
  }

  ValueNotifier<AppLifecycleState>? _lifecycleNotifier;

  void attachLifecycleNotifier(
      ValueNotifier<AppLifecycleState> lifecycleNotifier) {
    if (_lifecycleNotifier != null) {
      _lifecycleNotifier!.removeListener(_handleAppLifecycle);
    }
    _lifecycleNotifier = lifecycleNotifier;
    _lifecycleNotifier?.addListener(_handleAppLifecycle);
  }

  @override
  void dispose() {
    _lifecycleNotifier?.removeListener(_handleAppLifecycle);
    super.dispose();
  }

  void _handleAppLifecycle() {
    switch (_lifecycleNotifier!.value) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _audioSystem?.stopAllSound();
        break;
      case AppLifecycleState.resumed:
        if (!_muted && _musicOn) {
          _audioSystem?.resumeMusic();
        }
        break;
      case AppLifecycleState.inactive:
        // No need to react to this state change.
        break;
    }
  }
}
