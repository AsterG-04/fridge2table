import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/ingredient.dart';
import '../models/sync_result.dart';
import 'api_service.dart';

/// Cloud backup/restore for the local pantry, backed by a single Supabase
/// table. Rows are matched by id, which mirrors the local SQLite id rather
/// than being independently assigned by Supabase — correct for one local
/// backend talking to one cloud project, but not a strict multi-device
/// mirror: an ingredient created purely on the cloud side (or pulled down
/// after a local wipe) is inserted locally with a *new* local id, since the
/// local backend's create endpoint always assigns its own autoincrement id.
class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Set right before launching the Google OAuth flow and cleared once
  /// handled. signInWithOAuth() only launches the browser — it resolves
  /// long before the user finishes authenticating, so the app can't tell
  /// from that call alone when sign-in actually completes. The real
  /// completion arrives later as a `signedIn` event on
  /// `auth.onAuthStateChange` (via the deep-link redirect), which a
  /// password sign-in *also* emits. This flag lets the app-root listener
  /// in main.dart tell those two cases apart and only act on the OAuth one
  /// — password/sign-up flows already handle their own navigation directly.
  static bool oauthInProgress = false;

  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  static bool _isNewer(DateTime? a, DateTime? b) {
    if (a == null) return false;
    if (b == null) return true;
    return a.isAfter(b);
  }

  /// Pushes every local ingredient to Supabase (upsert by id) — a
  /// straightforward one-way backup, always safe to run.
  static Future<SyncResult> syncToCloud() async {
    if (!SupabaseConfig.isConfigured) {
      return SyncResult.failure("Cloud sync isn't configured yet");
    }

    try {
      final local = await ApiService.getInventory();

      if (local.isEmpty) {
        return const SyncResult(success: true, message: "Nothing to sync", syncedCount: 0);
      }

      await _client
          .from(SupabaseConfig.ingredientsTable)
          .upsert(local.map((i) => i.toSupabaseJson()).toList());

      return SyncResult(
        success: true,
        message: "Synced ${local.length} item${local.length == 1 ? '' : 's'} to cloud",
        syncedCount: local.length,
      );
    } catch (e) {
      return SyncResult.failure("Sync to cloud failed: $e");
    }
  }

  /// Pulls Supabase rows down: existing local rows are updated only if the
  /// cloud version is newer, cloud-only rows are created locally.
  static Future<SyncResult> syncFromCloud() async {
    if (!SupabaseConfig.isConfigured) {
      return SyncResult.failure("Cloud sync isn't configured yet");
    }

    try {
      final cloudRows = await _client.from(SupabaseConfig.ingredientsTable).select();
      final cloud = cloudRows.map(Ingredient.fromJson).toList();

      final local = await ApiService.getInventory();
      final localById = {for (final i in local) if (i.id != null) i.id!: i};

      int applied = 0;
      for (final cloudItem in cloud) {
        final localItem = cloudItem.id == null ? null : localById[cloudItem.id];

        if (localItem == null) {
          await ApiService.addIngredient(cloudItem);
          applied++;
          continue;
        }

        if (_isNewer(cloudItem.updatedAt, localItem.updatedAt) && localItem.id != null) {
          await ApiService.updateIngredient(localItem.id!, cloudItem);
          applied++;
        }
      }

      return SyncResult(
        success: true,
        message: "Pulled $applied update${applied == 1 ? '' : 's'} from cloud",
        syncedCount: applied,
      );
    } catch (e) {
      return SyncResult.failure("Sync from cloud failed: $e");
    }
  }

  /// Full two-way merge: for every ingredient id present on either side,
  /// the row with the newest updated_at wins and is written to the other
  /// side; ids present on only one side are copied to the other.
  static Future<SyncResult> resolveConflicts() async {
    if (!SupabaseConfig.isConfigured) {
      return SyncResult.failure("Cloud sync isn't configured yet");
    }

    try {
      final local = await ApiService.getInventory();
      final cloudRows = await _client.from(SupabaseConfig.ingredientsTable).select();
      final cloud = cloudRows.map(Ingredient.fromJson).toList();

      final localById = {for (final i in local) if (i.id != null) i.id!: i};
      final cloudById = {for (final i in cloud) if (i.id != null) i.id!: i};

      final allIds = {...localById.keys, ...cloudById.keys};
      int changes = 0;

      for (final id in allIds) {
        final localItem = localById[id];
        final cloudItem = cloudById[id];

        if (localItem == null && cloudItem != null) {
          await ApiService.addIngredient(cloudItem);
          changes++;
        } else if (cloudItem == null && localItem != null) {
          await _client.from(SupabaseConfig.ingredientsTable).upsert(localItem.toSupabaseJson());
          changes++;
        } else if (localItem != null && cloudItem != null) {
          if (_isNewer(cloudItem.updatedAt, localItem.updatedAt)) {
            await ApiService.updateIngredient(id, cloudItem);
            changes++;
          } else if (_isNewer(localItem.updatedAt, cloudItem.updatedAt)) {
            await _client.from(SupabaseConfig.ingredientsTable).upsert(localItem.toSupabaseJson());
            changes++;
          }
        }
      }

      return SyncResult(
        success: true,
        message: "Resolved sync — $changes change${changes == 1 ? '' : 's'} applied",
        syncedCount: changes,
      );
    } catch (e) {
      return SyncResult.failure("Sync failed: $e");
    }
  }
}
