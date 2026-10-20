import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/mock_repository.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';

/// Backend keys, passed at build time:
///
///   flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co \
///               --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
///
/// Without them every app runs on demo data.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Map tiles. OpenStreetMap's public server is fine for testing; switch to
  /// a paid provider (e.g. MapTiler) before launch, see docs/integrations.md.
  static const mapTilesUrl = String.fromEnvironment(
    'MAP_TILES_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// WhatsApp number for customer support, international format without +.
  static const supportWhatsApp = String.fromEnvironment(
    'SUPPORT_WHATSAPP',
    defaultValue: '201000000000',
  );

  static bool get hasBackend => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}

/// Creates the backend for an app: Supabase when configured, demo data otherwise.
Future<MyOrdersRepository> createRepository({
  bool simulateProgress = false,
  MockRepository Function()? demo,
}) async {
  if (!AppConfig.hasBackend) {
    return demo?.call() ?? MockRepository(simulateProgress: simulateProgress);
  }
  await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseKey);
  final repo = SupabaseRepository(Supabase.instance.client);
  await repo.init();
  return repo;
}
