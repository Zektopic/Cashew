import 'dart:async';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/dropdownSelect.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

LogService logService = LogService();

class LogService {
  static const int maxLogSize = 12500;
  static const int minLogSize = 10000;

  final List<String> _logs = [];

  final List<String> filterKeywords = [
    "[🌎 Easy Localization] [WARNING]",
  ];

  void log(String message) {
    if (appStateSettings["logging"] == true) {
      bool shouldLog =
          !filterKeywords.any((keyword) => message.contains(keyword));
      if (shouldLog) {
        // Prevent log forging/injection by sanitizing newlines
        String sanitizedMessage =
            message.replaceAll('\r', '\\r').replaceAll('\n', '\\n');
        _logs.insert(0, "[${DateTime.now()}] : $sanitizedMessage");
      }

      if (_logs.length > maxLogSize) {
        _logs.removeRange(minLogSize, _logs.length);
      }
    }

    Zone.root.run(() {
      print(message);
    });
  }

  String exportLogs() {
    return _logs.join('\n');
  }

  List<String> getLogs() => _logs;
}

captureLogs(Function body) {
  runZonedGuarded(
    () async {
      await body();
    },
    (error, stackTrace) {
      Zone.root.run(() {
        print("[captureLogs ERROR] $error\n$stackTrace");
      });
    },
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String message) {
        logService.log(message);
      },
    ),
  );
}

/// Log export that is safe to reach from a release build.
///
/// The full DebugPage stays gated behind allowDebugFlags (see main.dart)
/// because it exposes far more than logs, but collecting logs is a normal part
/// of filing a bug report. This offers only the logging toggle and an export,
/// and warns first: logs can contain transaction names, amounts and account
/// details, so sharing them is a disclosure the user should make knowingly.
void openLogExportPopup(BuildContext context) {
  openPopup(
    context,
    title: "Export Logs",
    description:
        "Logs help diagnose a bug, but they can contain your transaction "
        "names, amounts and account details. Only share them with someone you "
        "trust.\n\n"
        "If logging is off, turn it on, reproduce the problem, then export.",
    icon: appStateSettings["outlinedIcons"]
        ? Icons.bug_report_outlined
        : Icons.bug_report_rounded,
    onSubmitLabel: "Copy Logs",
    onSubmit: () {
      copyToClipboard(logService.exportLogs());
      popRoute(context);
    },
    onCancelLabel: appStateSettings["logging"] == true
        ? "Turn Off Logging"
        : "Turn On Logging",
    onCancel: () {
      updateSettings("logging", appStateSettings["logging"] != true,
          updateGlobalState: false);
      popRoute(context);
    },
  );
}

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFramework(
      title: "Logs",
      backButton: true,
      dragDownToDismiss: true,
      actions: [
        CustomPopupMenuButton(
          showButtons: true,
          keepOutFirst: true,
          items: [
            DropdownItemMenu(
              id: "share-logs",
              label: "info".tr(),
              icon: Icons.copy_all,
              action: () {
                copyToClipboard(logService.exportLogs());
              },
            ),
          ],
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: SettingsContainerSwitch(
            title: "Enable Logging",
            onSwitched: (value) {
              updateSettings("logging", value, updateGlobalState: false);
            },
            initialValue: appStateSettings["logging"] == true,
            icon: appStateSettings["outlinedIcons"]
                ? Icons.summarize_outlined
                : Icons.summarize_rounded,
          ),
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.symmetric(vertical: 7, horizontal: 13),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                String log = logService.getLogs()[index];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 4),
                  child: CodeBlock(
                    text: log,
                    fontSize: 13,
                    textAlign: TextAlign.left,
                    highlight: log.toLowerCase().contains("error"),
                  ),
                );
              },
              childCount: logService.getLogs().length,
            ),
          ),
        ),
      ],
    );
  }
}
