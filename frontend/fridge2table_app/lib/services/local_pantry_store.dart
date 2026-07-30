import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/ingredient.dart';
import 'user_scope.dart';

/// A single pending write against a locally-cached pantry row, applied on
/// top of whatever was last confirmed from the backend. There's exactly one
/// of these per row (not a queue of individual operations) -- editing the
/// same offline-created or offline-edited ingredient twice in a row just
/// overwrites this row's fields and leaves the action as-is, which is what
/// gives "last edit wins" for free once the row finally syncs, with no
/// extra conflict-resolution logic needed.
enum PendingAction { create, update, delete }

/// Local SQLite mirror of the backend's `pantry_items` table, so the
/// pantry can be viewed and edited with no network at all. Rows carry two
/// ids: [localId] (this table's own autoincrement primary key, stable from
/// the moment a row is created, online or off) and [serverId] (the
/// backend's `pantry_items.id`, null until a create actually reaches the
/// server). Screens never see either id directly -- ApiService maps
/// [serverId] to the ordinary positive [Ingredient.id] once known, and to
/// `-localId` (negative, unambiguous, never collides with a real server
/// id) while a create is still only local.
class LocalPantryStore {
  static Database? _db;

  static Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;

    final path = join(await getDatabasesPath(), 'fridge2table_local.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE pantry_items (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id INTEGER,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT NOT NULL,
            expiry_date TEXT,
            category TEXT,
            location TEXT,
            updated_at TEXT NOT NULL,
            pending_action TEXT
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  static Ingredient _fromRow(Map<String, Object?> row) {
    final serverId = row['server_id'] as int?;
    final localId = row['local_id'] as int;
    return Ingredient(
      // Positive = a real, synced backend id. Negative = "this row only
      // exists locally so far" -- -localId is always unique and always
      // recognizable as "not a server id" without needing a separate flag
      // threaded through every call site that already just handles
      // Ingredient.id as a plain int.
      id: serverId ?? -localId,
      name: row['name'] as String,
      quantity: row['quantity'] as double,
      unit: row['unit'] as String,
      expiryDate: row['expiry_date'] as String?,
      category: row['category'] as String?,
      location: row['location'] as String?,
      updatedAt: DateTime.tryParse(row['updated_at'] as String),
    );
  }

  /// Every visible ingredient for the current user -- synced rows and
  /// anything with a pending create/update. Rows pending delete are
  /// already gone as far as the UI is concerned; they only stick around
  /// under the hood until the delete actually reaches the server.
  static Future<List<Ingredient>> getVisibleInventory() async {
    final db = await _database;
    final userId = await UserScope.uid;
    final rows = await db.query(
      'pantry_items',
      where: 'user_id = ? AND (pending_action IS NULL OR pending_action != ?)',
      whereArgs: [userId, PendingAction.delete.name],
      orderBy: 'local_id DESC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Replaces every non-pending row with a fresh snapshot from the backend
  /// -- called right after a successful online fetch, so the cache always
  /// reflects the server the moment connectivity confirms it's reachable.
  /// Deliberately leaves any row with a pending_action alone: those are
  /// local changes that haven't reached the server yet, and blowing them
  /// away here would silently discard an offline edit the instant the
  /// network happened to come back before the sync pass ran.
  ///
  /// Also skips re-inserting a server item whose id still has a pending
  /// row -- normally the sync pass (_pushPendingChanges) clears pending rows
  /// before this ever runs, so this only matters when a specific row failed
  /// to push for some other reason (not connectivity -- that would have
  /// stopped the whole pass before reaching a fetch at all) while the rest
  /// of the pantry loaded fine. Without this check, the still-pending row
  /// and a freshly inserted copy of the server's (not-yet-updated) version
  /// of the same ingredient would both exist side by side, showing as a
  /// duplicate.
  static Future<void> cacheServerSnapshot(List<Ingredient> serverItems) async {
    final db = await _database;
    final userId = await UserScope.uid;

    await db.transaction((txn) async {
      final pendingRows = await txn.query(
        'pantry_items',
        columns: ['server_id'],
        where:
            'user_id = ? AND pending_action IS NOT NULL '
            'AND server_id IS NOT NULL',
        whereArgs: [userId],
      );
      final pendingServerIds = pendingRows
          .map((r) => r['server_id'] as int)
          .toSet();

      await txn.delete(
        'pantry_items',
        where: 'user_id = ? AND pending_action IS NULL',
        whereArgs: [userId],
      );
      for (final item in serverItems) {
        if (pendingServerIds.contains(item.id)) continue;
        await txn.insert('pantry_items', {
          'server_id': item.id,
          'user_id': userId,
          'name': item.name,
          'quantity': item.quantity,
          'unit': item.unit,
          'expiry_date': item.expiryDate,
          'category': item.category,
          'location': item.location,
          'updated_at': (item.updatedAt ?? DateTime.now().toUtc())
              .toIso8601String(),
          'pending_action': null,
        });
      }
    });
  }

  /// Records a brand-new ingredient locally with no server id yet, marked
  /// pending_action='create'. Returns the same ingredient with its id
  /// filled in as the negative local placeholder described on the class.
  static Future<Ingredient> queueCreate(Ingredient ingredient) async {
    final db = await _database;
    final userId = await UserScope.uid;
    final localId = await db.insert('pantry_items', {
      'server_id': null,
      'user_id': userId,
      'name': ingredient.name,
      'quantity': ingredient.quantity,
      'unit': ingredient.unit,
      'expiry_date': ingredient.expiryDate,
      'category': ingredient.category,
      'location': ingredient.location,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'pending_action': PendingAction.create.name,
    });
    return Ingredient(
      id: -localId,
      name: ingredient.name,
      quantity: ingredient.quantity,
      unit: ingredient.unit,
      expiryDate: ingredient.expiryDate,
      category: ingredient.category,
      location: ingredient.location,
    );
  }

  /// Applies an edit to the row behind [uiId] (as returned by [_fromRow] --
  /// positive means a server id, negative means -localId). A row that's
  /// still only a pending create just gets its fields amended in place
  /// (there's nothing to "update" server-side yet); anything else moves to
  /// pending_action='update' so the sync pass knows to PUT it.
  static Future<void> queueUpdate(int uiId, Ingredient ingredient) async {
    final db = await _database;
    final userId = await UserScope.uid;
    final row = await _rowForUiId(db, userId, uiId);
    if (row == null) return;

    final wasCreate = row['pending_action'] == PendingAction.create.name;
    await db.update(
      'pantry_items',
      {
        'name': ingredient.name,
        'quantity': ingredient.quantity,
        'unit': ingredient.unit,
        'expiry_date': ingredient.expiryDate,
        'category': ingredient.category,
        'location': ingredient.location,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'pending_action': wasCreate
            ? PendingAction.create.name
            : PendingAction.update.name,
      },
      where: 'local_id = ?',
      whereArgs: [row['local_id']],
    );
  }

  /// Marks the row behind [uiId] for deletion. A row that was only ever a
  /// local pending create is simply removed outright -- the server never
  /// knew it existed, so there's nothing to reconcile. Anything else is
  /// soft-deleted (pending_action='delete', hidden from
  /// [getVisibleInventory]) until the sync pass pushes the real delete.
  static Future<void> queueDelete(int uiId) async {
    final db = await _database;
    final userId = await UserScope.uid;
    final row = await _rowForUiId(db, userId, uiId);
    if (row == null) return;

    if (row['pending_action'] == PendingAction.create.name) {
      await db.delete(
        'pantry_items',
        where: 'local_id = ?',
        whereArgs: [row['local_id']],
      );
      return;
    }

    await db.update(
      'pantry_items',
      {'pending_action': PendingAction.delete.name},
      where: 'local_id = ?',
      whereArgs: [row['local_id']],
    );
  }

  /// Every row across all users with a pending write -- used by the sync
  /// pass, which needs the raw server_id/local_id rather than the
  /// UI-facing collapsed id.
  static Future<List<Map<String, Object?>>> getPendingRows() async {
    final db = await _database;
    return db.query(
      'pantry_items',
      where: 'pending_action IS NOT NULL',
      orderBy: 'local_id ASC',
    );
  }

  /// Rebuilds the [Ingredient] a raw pending row (as returned by
  /// [getPendingRows]) represents -- exposed for the sync pass, which reads
  /// rows directly rather than through [getVisibleInventory].
  static Ingredient ingredientFromRow(Map<String, Object?> row) =>
      _fromRow(row);

  /// Clears the pending flag for whichever row [uiId] currently resolves
  /// to, once an online write for it has been confirmed by the server --
  /// used by the "write locally, then also try the network immediately"
  /// path for edits made while online, as distinct from the queued
  /// catch-up sync pass (which already has the raw local_id).
  static Future<void> markSyncedForUiId(int uiId, {int? newServerId}) async {
    final db = await _database;
    final userId = await UserScope.uid;
    final row = await _rowForUiId(db, userId, uiId);
    if (row == null) return;
    await markSynced(row['local_id'] as int, newServerId: newServerId);
  }

  /// Removes whichever row [uiId] currently resolves to outright, once a
  /// delete for it has been confirmed by the server -- a confirmed delete
  /// must drop the row entirely rather than just clear pending_action,
  /// since a cleared pending_action would make [getVisibleInventory] treat
  /// it as an ordinary synced row again instead of gone.
  static Future<void> confirmDeleteForUiId(int uiId) async {
    final db = await _database;
    final userId = await UserScope.uid;
    final row = await _rowForUiId(db, userId, uiId);
    if (row == null) return;
    await deleteLocalRow(row['local_id'] as int);
  }

  static Future<void> markSynced(int localId, {int? newServerId}) async {
    final db = await _database;
    await db.update(
      'pantry_items',
      {'server_id': ?newServerId, 'pending_action': null},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  static Future<void> deleteLocalRow(int localId) async {
    final db = await _database;
    await db.delete(
      'pantry_items',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  static Future<Map<String, Object?>?> _rowForUiId(
    Database db,
    String userId,
    int uiId,
  ) async {
    final rows = await db.query(
      'pantry_items',
      where: uiId < 0
          ? 'user_id = ? AND local_id = ?'
          : 'user_id = ? AND server_id = ?',
      whereArgs: [userId, uiId < 0 ? -uiId : uiId],
    );
    return rows.isEmpty ? null : rows.first;
  }
}
