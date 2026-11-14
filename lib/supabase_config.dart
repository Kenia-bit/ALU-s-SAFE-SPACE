class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bcdevhhkavpyyatkjobu.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJjZGV2aGhrYXZweXlhdGtqb2J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ0MDQ4NjUsImV4cCI6MjEwOTk4MDg2NX0.yemkpYxj1azgz-2pv8gqZrM__5TKdL8ZFHgZE0IF6yM',
  );

  static const String storageBucket = 'report-photos';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}