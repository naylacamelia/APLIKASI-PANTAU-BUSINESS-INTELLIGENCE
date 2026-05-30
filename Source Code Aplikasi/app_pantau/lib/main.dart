import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
  
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mexpjxfgmjmfzapgbrxm.supabase.co',
    anonKey: 'sb_publishable_AMoG9aPuWGg7Qk7P4W9wyQ_GSFBfxdT',
  );

  runApp(const PantauUmkmApp());
}
