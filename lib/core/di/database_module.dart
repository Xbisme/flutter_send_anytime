import 'package:injectable/injectable.dart';
import 'package:safe_send/core/data/database/app_database.dart';

/// Provides the shared [AppDatabase] to the DI graph (#006). A lazy singleton —
/// one connection opened on first use, shared by every feature that reads or
/// writes history (Constitution XI: shared services are singletons). The
/// connection lives for the app's lifetime; tests construct their own in-memory
/// [AppDatabase] directly.
@module
abstract class DatabaseModule {
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();
}
