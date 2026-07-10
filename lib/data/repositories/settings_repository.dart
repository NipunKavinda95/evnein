import '../models/app_settings_model.dart';
import '../../core/services/firebase_service.dart';

class SettingsRepository {
  static final _doc =
      FirebaseService.firestore.collection('settings').doc('app');

  static Stream<AppSettingsModel> getSettingsStream() {
    return FirebaseService.auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(AppSettingsModel());
      return _doc.snapshots().map((snap) {
        if (snap.exists && snap.data() != null) {
          return AppSettingsModel.fromMap(snap.data()!);
        }
        return AppSettingsModel();
      }).handleError((_) => AppSettingsModel());
    });
  }

  static Future<void> saveSettings(AppSettingsModel settings) async {
    await _doc.set(settings.toMap());
  }

  static Future<AppSettingsModel> getSettings() async {
    try {
      final snap = await _doc.get();
      if (snap.exists && snap.data() != null) {
        return AppSettingsModel.fromMap(snap.data()!);
      }
    } catch (e) {
      // ignore
    }
    return AppSettingsModel();
  }
}
