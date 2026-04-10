import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/explorer_file_crud_repository.dart';
import '../../domain/repositories/explorer_repository.dart';
import 'mock_explorer_file_crud_repository.dart';
import 'mock_explorer_repository.dart';
import 'supabase_explorer_file_crud_repository.dart';
import 'supabase_explorer_repository.dart';

class ExplorerRepositoryFactory {
  static ExplorerRepository create() {
    const useSupabase = bool.fromEnvironment('USE_SUPABASE_EXPLORER', defaultValue: false);
    const workspaceId = String.fromEnvironment('FILEZEN_WORKSPACE_ID', defaultValue: '');
    const dbSchema = String.fromEnvironment('FILEZEN_DB_SCHEMA', defaultValue: 'app');

    if (!useSupabase) {
      return MockExplorerRepository();
    }

    if (!_isSupabaseReady()) {
      return MockExplorerRepository(scenario: MockExplorerScenario.error);
    }

    return SupabaseExplorerRepository(
      client: Supabase.instance.client,
      workspaceId: workspaceId.isEmpty ? null : workspaceId,
      dbSchema: dbSchema,
    );
  }

  static bool _isSupabaseReady() {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  static ExplorerFileCrudRepository createFileCrud() {
    const useSupabase = bool.fromEnvironment('USE_SUPABASE_EXPLORER', defaultValue: false);
    const workspaceId = String.fromEnvironment('FILEZEN_WORKSPACE_ID', defaultValue: '');
    const dbSchema = String.fromEnvironment('FILEZEN_DB_SCHEMA', defaultValue: 'app');
    if (!useSupabase || !_isSupabaseReady()) {
      return MockExplorerFileCrudRepository();
    }
    return SupabaseExplorerFileCrudRepository(
      Supabase.instance.client,
      workspaceId: workspaceId,
      dbSchema: dbSchema,
    );
  }
}
