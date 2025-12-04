import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite database helper for local data persistence.
///
/// Manages database creation, versioning, and provides access to the database
/// instance for local data sources. Used for offline cart and favorites.
class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  /// Singleton instance.
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  /// Database name.
  static const String _databaseName = 'ai_flutter.db';

  /// Current database version.
  static const int _databaseVersion = 1;

  /// Table names.
  static const String cartItemsTable = 'cart_items';
  static const String favoriteProductsTable = 'favorite_products';

  /// Get the database instance, initializing if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database.
  Future<Database> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables on first run.
  Future<void> _onCreate(Database db, int version) async {
    // Create cart_items table
    await db.execute('''
      CREATE TABLE $cartItemsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        variant_id TEXT,
        quantity INTEGER NOT NULL,
        added_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        product_data TEXT NOT NULL
      )
    ''');

    // Create favorite_products table
    await db.execute('''
      CREATE TABLE $favoriteProductsTable (
        product_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        added_at TEXT NOT NULL,
        product_data TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_cart_user_id ON $cartItemsTable(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_favorite_user_id ON $favoriteProductsTable(user_id)
    ''');
  }

  /// Handle database upgrades for future schema changes.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle schema migrations when database version is incremented
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE cart_items ADD COLUMN new_field TEXT');
    // }
  }

  /// Close the database.
  Future<void> close() async {
    final Database db = await database;
    await db.close();
    _database = null;
  }

  /// Delete the database file.
  ///
  /// Use with caution - this removes ALL local data.
  Future<void> deleteDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Clear all data from a specific table.
  Future<int> clearTable(String tableName) async {
    final Database db = await database;
    return db.delete(tableName);
  }

  /// Get the current database version.
  Future<int> getDatabaseVersion() async {
    final Database db = await database;
    return db.getVersion();
  }
}
