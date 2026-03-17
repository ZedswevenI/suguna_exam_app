
import 'package:get_storage/get_storage.dart';

class StorageService {
  final _box = GetStorage();

  // Save full login response
  void saveUser(Map<String, dynamic> data) {
    _box.write('user', data);
  }

  Map<String, dynamic>? getUser() {
    return _box.read('user');
  }

  void clearUser() {
    _box.remove('user');
  }

  // Save full login response
  void saveSubjects(Map<String, dynamic> data) {
    _box.write('subjects', data);
  }

  Map<String, dynamic>? getSubjects() {
    return _box.read('subjects');
  }

  // void saveTopics(Map<String, dynamic> data) {
  //   _box.write('topics', data);
  // }
  void saveTopics(Map<String, dynamic> newData) {
    final existing = _box.read('topics') ?? {};
    final updated = {...existing, ...newData};
    _box.write('topics', updated);
  }

  Map<dynamic, dynamic>? getGetTopics() {
    return _box.read('topics');
  }

  void clearSubjects() {
    _box.remove('subjects');
  }

  void save(String key, dynamic data) {
    _box.write(key, data);
  }

  dynamic read(String key) {
    return _box.read(key);
  }

  List<dynamic> getAllKeys() {
    return _box.getKeys().toList();
  }

  void removeByKey(String key) {
    _box.remove(key);
  }

  void clearAllExceptUser() {
    try {
      final userData = _box.read('user'); // backup user
      _box.erase(); // 🚨 clears everything
      if (userData != null) {
        _box.write('user', userData); // restore user
      }
      print("✅ Local storage cleared (user preserved)");
    } catch (e) {
      print("❌ Error clearing storage: $e");
    }
  }

  bool get isLoggedIn => _box.hasData('user');
}