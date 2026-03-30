import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../customer_history/domain/entities/key_code_entry_entity.dart';
import '../../domain/repositories/key_code_repository.dart';
import '../datasources/key_code_local_datasource.dart';
import '../datasources/key_code_remote_datasource.dart';
import '../models/key_code_entry_model.dart';

class KeyCodeRepositoryImpl implements KeyCodeRepository {
  final KeyCodeLocalDatasource _local;
  final KeyCodeRemoteDatasource _remote;
  final ConnectivityService _connectivity;
  final String _userId;

  KeyCodeRepositoryImpl(this._local, this._remote, this._connectivity, this._userId);

  // Derives a 32-byte AES key using iterated SHA-256 (poor-man's KDF).
  // Prefix 'gcm:' on ciphertext marks the new GCM format.
  // Legacy CBC ciphertext has no prefix and is decrypted with the old scheme for migration.
  enc.Key get _encryptionKey {
    // 10 rounds of SHA-256 over userId + fixed salt — harder to brute-force than single round.
    List<int> bytes = utf8.encode('$_userId-ks-keycodes-v2');
    for (int i = 0; i < 10000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return enc.Key(Uint8List.fromList(bytes));
  }

  enc.Key get _legacyEncryptionKey {
    final bytes = sha256.convert(utf8.encode('$_userId-ks-keycodes-v1')).bytes;
    return enc.Key(Uint8List.fromList(bytes));
  }

  String _encrypt(String plaintext) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_encryptionKey, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return 'gcm:${iv.base64}:${encrypted.base64}';
  }

  String _decrypt(String ciphertext) {
    // New GCM format: 'gcm:<iv>:<ciphertext>'
    if (ciphertext.startsWith('gcm:')) {
      final parts = ciphertext.substring(4).split(':');
      if (parts.length != 2) return '';
      try {
        final iv = enc.IV.fromBase64(parts[0]);
        final encrypter = enc.Encrypter(enc.AES(_encryptionKey, mode: enc.AESMode.gcm));
        return encrypter.decrypt64(parts[1], iv: iv);
      } catch (e) {
        debugPrint('[KS:KEYCODES] GCM decrypt failed: $e');
        return '';
      }
    }
    // Legacy CBC format: '<iv>:<ciphertext>' — decrypt and caller will re-encrypt as GCM on next save.
    final parts = ciphertext.split(':');
    if (parts.length != 2) return ciphertext;
    try {
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(_legacyEncryptionKey, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (e) {
      debugPrint('[KS:KEYCODES] Legacy CBC decrypt failed: $e');
      return '';
    }
  }

  KeyCodeEntryModel _modelWithEncryptedBitting(KeyCodeEntryEntity entity) {
    final encrypted = entity.bitting != null ? _encrypt(entity.bitting!) : null;
    return KeyCodeEntryModel.fromEntity(entity, encryptedBitting: encrypted);
  }

  KeyCodeEntryEntity _entityWithDecryptedBitting(KeyCodeEntryModel model) {
    final decrypted = model.bitting != null ? _decrypt(model.bitting!) : null;
    // Auto-migrate legacy CBC records to GCM on next read.
    if (model.bitting != null && !model.bitting!.startsWith('gcm:') && decrypted != null && decrypted.isNotEmpty) {
      final upgraded = KeyCodeEntryModel.fromEntity(model.toEntity(decryptedBitting: decrypted), encryptedBitting: _encrypt(decrypted));
      _local.save(upgraded);
    }
    return model.toEntity(decryptedBitting: decrypted);
  }

  @override
  Future<List<KeyCodeEntryEntity>> getKeyCodesForCustomer(String customerId) async {
    if (await _connectivity.isConnected) {
      try {
        final remoteModels = await _remote.getForCustomer(customerId);
        for (final m in remoteModels) {
          await _local.save(m); // remote already stores encrypted data
        }
      } catch (e) {
        debugPrint('[KS:KEYCODES] Remote fetch failed: $e');
      }
    }
    final localModels = await _local.getForCustomer(customerId);
    return localModels.map(_entityWithDecryptedBitting).toList();
  }

  @override
  Future<KeyCodeEntryEntity> createKeyCode(KeyCodeEntryEntity entry) async {
    final model = _modelWithEncryptedBitting(entry);
    await _local.save(model);
    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.create(model.toJson());
        await _local.save(remoteModel);
        return _entityWithDecryptedBitting(remoteModel);
      } catch (e) {
        debugPrint('[KS:KEYCODES] Remote create failed: $e');
      }
    }
    return _entityWithDecryptedBitting(model);
  }

  @override
  Future<KeyCodeEntryEntity> updateKeyCode(KeyCodeEntryEntity entry) async {
    final model = _modelWithEncryptedBitting(entry);
    await _local.save(model);
    if (await _connectivity.isConnected) {
      try {
        final remoteModel = await _remote.update(entry.id, model.toJson());
        await _local.save(remoteModel);
        return _entityWithDecryptedBitting(remoteModel);
      } catch (e) {
        debugPrint('[KS:KEYCODES] Remote update failed: $e');
      }
    }
    return _entityWithDecryptedBitting(model);
  }

  @override
  Future<void> deleteKeyCode(String id) async {
    await _local.delete(id);
    if (await _connectivity.isConnected) {
      try {
        await _remote.delete(id);
      } catch (e) {
        debugPrint('[KS:KEYCODES] Remote delete failed: $e');
      }
    }
  }
}

