import 'dart:convert';

import 'package:finova/core/database/finova_database.dart';
import 'package:finova/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CloudBackupInfo {
  const CloudBackupInfo({required this.fileId, required this.modifiedAt});
  final String fileId;
  final DateTime? modifiedAt;
}

class BackupService {
  BackupService(this._database, this._preferences);

  static const _fileName = 'finova-backup.json';
  static const _api = 'https://www.googleapis.com/drive/v3';
  static const _uploadApi = 'https://www.googleapis.com/upload/drive/v3';
  static const _preferenceKeys = <String>[
    'currency',
    'initial_balance',
    'theme',
    'notifications',
    'ads_enabled',
    'onboarding_complete',
  ];

  final FinovaDatabase _database;
  final SharedPreferences _preferences;

  Future<CloudBackupInfo?> latestBackup() async {
    final response = await http.get(
      Uri.parse(
        '$_api/files?spaces=appDataFolder&q=${Uri.encodeQueryComponent("name = '$_fileName' and trashed = false")}&fields=files(id,modifiedTime)&orderBy=modifiedTime desc&pageSize=1',
      ),
      headers: await AuthService.instance.driveAuthorizationHeaders(),
    );
    _ensureSuccess(response);
    final files = (jsonDecode(response.body) as Map<String, dynamic>)['files'];
    if (files is! List || files.isEmpty) return null;
    final file = Map<String, dynamic>.from(files.first as Map);
    return CloudBackupInfo(
      fileId: file['id'] as String,
      modifiedAt: DateTime.tryParse(file['modifiedTime'] as String? ?? ''),
    );
  }

  Future<DateTime> createBackup() async {
    final user = AuthService.instance.user;
    if (user == null) throw StateError('Masuk dengan Google terlebih dahulu.');
    final now = DateTime.now().toUtc();
    final preferences = <String, Object?>{};
    for (final key in _preferenceKeys) {
      final value = _preferences.get(key);
      if (value is String || value is int || value is bool || value is double) {
        preferences[key] = value;
      }
    }
    final content = jsonEncode({
      'schemaVersion': 1,
      'createdAt': now.toIso8601String(),
      'userId': user.id,
      'preferences': preferences,
      'tables': await _database.exportData(),
    });
    final existing = await latestBackup();
    final uri = existing == null
        ? Uri.parse(
            '$_uploadApi/files?uploadType=multipart&fields=id,modifiedTime',
          )
        : Uri.parse(
            '$_uploadApi/files/${existing.fileId}?uploadType=multipart&fields=id,modifiedTime',
          );
    final boundary = 'finova_${now.microsecondsSinceEpoch}';
    final metadata = jsonEncode({
      'name': _fileName,
      if (existing == null) 'parents': ['appDataFolder'],
    });
    final body = utf8.encode(
      '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n$metadata\r\n'
      '--$boundary\r\nContent-Type: application/json\r\n\r\n$content\r\n'
      '--$boundary--',
    );
    final headers = await AuthService.instance.driveAuthorizationHeaders();
    headers['Content-Type'] = 'multipart/related; boundary=$boundary';
    final response = existing == null
        ? await http.post(uri, headers: headers, body: body)
        : await http.patch(uri, headers: headers, body: body);
    _ensureSuccess(response);
    await _preferences.setString('last_backup_at', now.toIso8601String());
    return now.toLocal();
  }

  Future<DateTime> restoreBackup() async {
    final info = await latestBackup();
    if (info == null) throw StateError('Backup Google Drive belum tersedia.');
    final response = await http.get(
      Uri.parse('$_api/files/${info.fileId}?alt=media'),
      headers: await AuthService.instance.driveAuthorizationHeaders(),
    );
    _ensureSuccess(response);
    final payload = jsonDecode(utf8.decode(response.bodyBytes));
    if (payload is! Map<String, dynamic> || payload['schemaVersion'] != 1) {
      throw const FormatException('Versi backup tidak didukung.');
    }
    final currentUser = AuthService.instance.user;
    if (currentUser == null || payload['userId'] != currentUser.id) {
      throw StateError('Backup ini bukan milik akun yang sedang digunakan.');
    }
    final tables = payload['tables'];
    final preferences = payload['preferences'];
    if (tables is! Map<String, dynamic> ||
        preferences is! Map<String, dynamic>) {
      throw const FormatException('Struktur backup tidak valid.');
    }
    await _database.importData(tables);
    for (final key in _preferenceKeys) {
      final value = preferences[key];
      if (value is String) await _preferences.setString(key, value);
      if (value is int) await _preferences.setInt(key, value);
      if (value is bool) await _preferences.setBool(key, value);
      if (value is double) await _preferences.setDouble(key, value);
    }
    await _preferences.setString(
      'last_backup_at',
      (info.modifiedAt ?? DateTime.now().toUtc()).toIso8601String(),
    );
    return info.modifiedAt?.toLocal() ?? DateTime.now();
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw StateError('Google Drive gagal (${response.statusCode}).');
  }
}
