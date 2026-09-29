import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tacktics/screens/home/home_screen.dart';
import 'package:tacktics/util/error_handling.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Vor allem anderen: ab hier landet jeder Fehler im Log statt im Nichts —
  // auch einer, der noch beim Hochfahren passiert.
  installErrorHandlers();

  await Supabase.initialize(
    url: 'https://sepcmrnxnsodxmdubimc.supabase.co',
    publishableKey: 'sb_publishable_-DrQCFGTTHeNNTrhEeO1FA_rYC3fbZt',
  );

  // final auth = Supabase.instance.client.auth;
  // try {
  //   if (auth.currentSession == null) {
  //     await auth.signInAnonymously();
  //   } else {
  //   }
  // } catch (e) {
  //   // Offline beim Start ist ok — Anmeldung wird beim Upload nachgeholt
  // }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}
