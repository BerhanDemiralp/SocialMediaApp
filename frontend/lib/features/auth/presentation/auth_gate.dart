import 'package:flutter/material.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder auth UI; Supabase integration will be added in later tasks.
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to MOMENT')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Auth flow coming soon'),
          ],
        ),
      ),
    );
  }
}

