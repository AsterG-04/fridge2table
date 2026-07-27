import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/ingredient.dart';
import '../models/sync_result.dart';
import 'api_service.dart';
import 'delete_tombstones.dart';
import 'secure_storage_service.dart';

/// Cloud backup/restore for the local pantry, backed by a single Supabase
/// table shared by every account, with each row tagged by user_id and
/// isolated per-user via a Row Level Security policy (see
/// supabase_schema.sql). Rows are matched by id, which mirrors the local
/// SQLite id rather than being independently assigned by Supabase —
/// correct for one local backend talking to one cloud project, but not a
/// strict multi-device mirror: an ingredient created purely on the cloud
/// side (or pulled down after a local wipe) is inserted locally with a
/// *new* local id, since the local backend's create endpoint always
/// assigns its own autoincrement id.
class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// The cloud "ingredients" table is shared across every account using
  /// this Supabase project — every row is tagged with the owning user's
  /// id, both so the client only ever compares/merges its own rows and
  /// because the table's Row Level Security policy requires it (a row
  /// whose user_id doesn't match auth.uid() is rejected on write and
  /// invisible on read, regardless of what the client asks for).
  static String? get _userId => _client.auth.currentUser?.id;

  /// The app-root listener in main.dart reacts to every `signedIn` event on
  /// `auth.onAuthStateChange` by default — this is what catches sign-in
  /// completing *asynchronously* well after the call that triggered it
  /// already returned: Google OAuth (the browser redirect lands later) and
  /// email-confirmation links (opened from the user's inbox, potentially
  /// after the app was backgrounded). Neither can be handled by a simple
  /// awaited call.
  ///
  /// Email/password sign-in *can* be awaited directly, so it sets this flag
  /// to handle its own navigation instead of racing the root listener for
  /// the same event.
  static bool suppressRootAuthListener = false;

  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      // Persist the session (and PKCE code verifier, mid-OAuth-flow) in
      // flutter_secure_storage rather than the package's SharedPreferences
      // default — the persisted session is a live access/refresh token
      // pair, meaningfully sensitive since whoever holds it can act as the
      // signed-in user.
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureSupabaseLocalStorage(),
        pkceAsyncStorage: SecureSupabasePkceStorage(),
      ),
    );
  }

  /// Deletes a single ingredient's cloud row, mirroring a local delete.
  /// Returns whether the cloud row is confirmed gone (or never existed to
  /// begin with) -- callers use this to decide whether a delete tombstone
  /// (see DeleteTombstones) still needs to be kept around. Without a
  /// tombstone, a failed mirror-delete here means the surviving cloud row
  /// gets treated as "cloud-only" on the next sync and recreated locally,
  /// which is exactly how a deleted ingredient could come back as a
  /// duplicate after cooking deducted it to zero and deleted it locally.
  static Future<bool> deleteIngredient(int id) async {
    if (!SupabaseConfig.isConfigured) return true;
    final userId = _userId;
    if (userId == null) return true;

    try {
      await _client
          .from(SupabaseConfig.ingredientsTable)
          .delete()
          .eq("id", id)
          .eq("user_id", userId);
      return true;
    } catch (_) {
      // Offline right at delete time, etc. -- the caller's tombstone stays
      // in place so a later resync (resolveConflicts/syncFromCloud) can
      // finish this delete instead of resurrecting the row. A subsequent
      // manual delete retry would also still work fine since this call is
      // naturally idempotent.
      return false;
    }
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
    final userId = _userId;
    if (userId == null) {
      return SyncResult.failure("You must be signed in to sync");
    }

    try {
      final local = await ApiService.getInventory();

      if (local.isEmpty) {
        return const SyncResult(
          success: true,
          message: "Nothing to sync",
          syncedCount: 0,
        );
      }

      await _client
          .from(SupabaseConfig.ingredientsTable)
          // id alone isn't unique across accounts -- two users can both
          // have a local id=1, so the upsert's conflict target has to be
          // the (id, user_id) pair (see supabase_schema.sql's composite
          // unique constraint), or this silently updates a different
          // user's row via id collision instead of inserting a new one.
          .upsert(
            local.map((i) => i.toSupabaseJson(userId)).toList(),
            onConflict: "id,user_id",
          );

      return SyncResult(
        success: true,
        message:
            "Synced ${local.length} item${local.length == 1 ? '' : 's'} to cloud",
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
    final userId = _userId;
    if (userId == null) {
      return SyncResult.failure("You must be signed in to sync");
    }

    try {
      final cloudRows = await _client
          .from(SupabaseConfig.ingredientsTable)
          .select()
          .eq("user_id", userId);
      final cloud = cloudRows.map(Ingredient.fromJson).toList();

      final local = await ApiService.getInventory();
      final localById = {
        for (final i in local)
          if (i.id != null) i.id!: i,
      };
      final tombstones = await DeleteTombstones.load();

      int applied = 0;
      for (final cloudItem in cloud) {
        final localItem = cloudItem.id == null ? null : localById[cloudItem.id];

        if (localItem == null) {
          final id = cloudItem.id;
          if (id != null && tombstones.contains(id)) {
            // Deliberately deleted locally -- the mirror-delete never
            // landed, so finish it now instead of resurrecting the item.
            await deleteIngredient(id);
            await DeleteTombstones.remove(id);
            continue;
          }
          await ApiService.addIngredient(cloudItem);
          applied++;
          continue;
        }

        if (_isNewer(cloudItem.updatedAt, localItem.updatedAt) &&
            localItem.id != null) {
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
    final userId = _userId;
    if (userId == null) {
      return SyncResult.failure("You must be signed in to sync");
    }

    try {
      final local = await ApiService.getInventory();
      final cloudRows = await _client
          .from(SupabaseConfig.ingredientsTable)
          .select()
          .eq("user_id", userId);
      final cloud = cloudRows.map(Ingredient.fromJson).toList();

      final localById = {
        for (final i in local)
          if (i.id != null) i.id!: i,
      };
      final cloudById = {
        for (final i in cloud)
          if (i.id != null) i.id!: i,
      };

      final allIds = {...localById.keys, ...cloudById.keys};
      int changes = 0;
      final tombstones = await DeleteTombstones.load();

      for (final id in allIds) {
        final localItem = localById[id];
        final cloudItem = cloudById[id];

        if (localItem == null && cloudItem != null) {
          if (tombstones.contains(id)) {
            // Deliberately deleted locally -- the mirror-delete never
            // landed, so finish it now instead of resurrecting the item.
            await deleteIngredient(id);
            await DeleteTombstones.remove(id);
            continue;
          }
          await ApiService.addIngredient(cloudItem);
          changes++;
        } else if (cloudItem == null && localItem != null) {
          await _client
              .from(SupabaseConfig.ingredientsTable)
              .upsert(
                localItem.toSupabaseJson(userId),
                onConflict: "id,user_id",
              );
          changes++;
        } else if (localItem != null && cloudItem != null) {
          if (_isNewer(cloudItem.updatedAt, localItem.updatedAt)) {
            await ApiService.updateIngredient(id, cloudItem);
            changes++;
          } else if (_isNewer(localItem.updatedAt, cloudItem.updatedAt)) {
            await _client
                .from(SupabaseConfig.ingredientsTable)
                .upsert(
                  localItem.toSupabaseJson(userId),
                  onConflict: "id,user_id",
                );
            changes++;
          }
        }
      }

      return SyncResult(
        success: true,
        message:
            "Resolved sync — $changes change${changes == 1 ? '' : 's'} applied",
        syncedCount: changes,
      );
    } catch (e) {
      return SyncResult.failure("Sync failed: $e");
    }
  }
}
