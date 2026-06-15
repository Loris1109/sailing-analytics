import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sailing_analytics/screens/home/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sepcmrnxnsodxmdubimc.supabase.co',
    publishableKey: 'sb_publishable_-DrQCFGTTHeNNTrhEeO1FA_rYC3fbZt',
  );

  final auth = Supabase.instance.client.auth;
  try {
    if (auth.currentSession == null) {
      await auth.signInAnonymously();
      debugPrint('Anon sign-in NEU: ${auth.currentUser?.id}');
    } else {
      debugPrint('Schon angemeldet als: ${auth.currentUser?.id}');
    }
  } catch (e) {
    // Offline beim Start ist ok — Anmeldung wird beim Upload nachgeholt
    debugPrint('Anon sign-in failed: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}
