import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScope extends InheritedWidget {
  const AuthScope({super.key, required this.client, required super.child});
  final SupabaseClient? client;
  static SupabaseClient? clientOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.client;
  @override
  bool updateShouldNotify(AuthScope oldWidget) => client != oldWidget.client;
}
