import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/env.dart';
import '../../domain/repositories/explorer_file_crud_repository.dart';
import '../../domain/repositories/explorer_repository.dart';
import 'mock_explorer_file_crud_repository.dart';
import 'mock_explorer_repository.dart';
import 'supabase_explorer_file_crud_repository.dart';
import 'supabase_explorer_repository.dart';

class ExplorerRepositoryFactory {
  static ExplorerRepository create() {
    if (!Env.useSupabase) return MockExplorerRepository();
    if (!_isSupabaseReady()) return MockExplorerRepository(scenario: MockExplorerScenario.error);

    return SupabaseExplorerRepository(
      client: Supabase.instance.client,
      workspaceId: Env.workspaceId.isEmpty ? null : Env.workspaceId,
      dbSchema: Env.dbSchema,
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
    if (!Env.useSupabase || !_isSupabaseReady()) return MockExplorerFileCrudRepository();
    return SupabaseExplorerFileCrudRepository(
      Supabase.instance.client,
      workspaceId: Env.workspaceId,
      dbSchema: Env.dbSchema,
    );
  }
}
