import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/repositories/settings_repository.dart';

final settingsStreamProvider = StreamProvider<AppSettingsModel>((ref) {
  return SettingsRepository.getSettingsStream();
});

class SettingsNotifier extends StateNotifier<AsyncValue<void>> {
  SettingsNotifier() : super(const AsyncValue.data(null));

  Future<bool> saveSettings(AppSettingsModel settings) async {
    state = const AsyncValue.loading();
    try {
      await SettingsRepository.saveSettings(settings);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> updatePin(String newPin) async {
    state = const AsyncValue.loading();
    try {
      final current = await SettingsRepository.getSettings();
      await SettingsRepository.saveSettings(
        current.copyWith(adminPin: newPin),
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<void>>((ref) {
  return SettingsNotifier();
});
