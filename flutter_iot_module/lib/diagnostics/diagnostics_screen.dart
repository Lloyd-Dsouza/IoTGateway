import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../bridge/bridge_log.dart';
import 'diagnostics_log_card.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key, required this.log});

  final BridgeLog log;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: ListenableBuilder(
        listenable: log,
        builder: (context, _) {
          final entries = log.entries;

          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No Messages',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: entries.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              return DiagnosticsLogCard(entry: entries[index]);
            },
          );
        },
      ),
    );
  }
}
