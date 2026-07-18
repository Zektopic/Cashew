import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/encryptedBackup.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/exportCSV.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/util/saveFile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:async';

Future saveDBFileToDevice({
  required BuildContext boxContext,
  required String fileName,
  String? customDirectory,
}) async {
  try {
    await backupSettings();
  } catch (e) {
    print("Error creating settings entry in the db: " + e.toString());
  }

  DBFileInfo currentDBFileInfo = await getCurrentDBFileInfo();

  List<int> dataStore = [];
  await for (var data in currentDBFileInfo.mediaStream) {
    dataStore.insertAll(dataStore.length, data);
  }

  return await saveFile(
    boxContext: boxContext,
    dataStore: dataStore,
    dataString: null,
    fileName: fileName,
    successMessage: "backup-saved-success".tr(),
    errorMessage: "error-saving".tr(),
  );
}

Future exportDB({required BuildContext boxContext}) async {
  await openLoadingPopupTryCatch(() async {
    String fileName =
        "cashew-" + cleanFileNameString(DateTime.now().toString()) + ".sql";
    await saveDBFileToDevice(boxContext: boxContext, fileName: fileName);
  });
}

// Prompts for a backup password (optionally with confirmation).
// Returns null when cancelled, empty, or the confirmation does not match.
Future<String?> promptBackupPassword(
  BuildContext context, {
  required String title,
  bool confirm = false,
}) async {
  String password = "";
  String confirmPassword = "";
  dynamic result = await openBottomSheet(
    context,
    popupWithKeyboard: true,
    PopupFramework(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextInput(
            labelText: "Password",
            obscureText: true,
            autoFocus: true,
            autocorrect: false,
            padding: EdgeInsetsDirectional.zero,
            onChanged: (text) => password = text,
          ),
          if (confirm) SizedBox(height: 10),
          if (confirm)
            TextInput(
              labelText: "Confirm Password",
              obscureText: true,
              autocorrect: false,
              padding: EdgeInsetsDirectional.zero,
              onChanged: (text) => confirmPassword = text,
            ),
          SizedBox(height: 15),
          Button(
            label: "ok".tr(),
            onTap: () => popRoute(context, true),
          ),
        ],
      ),
    ),
  );
  if (result != true) return null;
  if (password.isEmpty) {
    openSnackbar(SnackbarMessage(
      title: "Password cannot be empty",
      icon: Icons.warning_rounded,
    ));
    return null;
  }
  if (confirm && password != confirmPassword) {
    openSnackbar(SnackbarMessage(
      title: "Passwords do not match",
      icon: Icons.warning_rounded,
    ));
    return null;
  }
  return password;
}

Future exportEncryptedDB({required BuildContext boxContext}) async {
  String? password = await promptBackupPassword(
    boxContext,
    title: "Set Backup Password",
    confirm: true,
  );
  if (password == null) return;
  await openLoadingPopupTryCatch(() async {
    try {
      await backupSettings();
    } catch (e) {
      print("Error creating settings entry in the db: " + e.toString());
    }
    DBFileInfo currentDBFileInfo = await getCurrentDBFileInfo();
    List<int> dataStore = [];
    await for (var data in currentDBFileInfo.mediaStream) {
      dataStore.insertAll(dataStore.length, data);
    }
    List<int> encrypted = await encryptBackupData(dataStore, password);
    String fileName =
        "cashew-" + cleanFileNameString(DateTime.now().toString()) + ".cashew";
    await saveFile(
      boxContext: boxContext,
      dataStore: encrypted,
      dataString: null,
      fileName: fileName,
      successMessage: "backup-saved-success".tr(),
      errorMessage: "error-saving".tr(),
    );
  });
}

class ExportEncryptedDB extends StatelessWidget {
  const ExportEncryptedDB({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (boxContext) {
      return SettingsContainer(
        onTap: () async {
          await exportEncryptedDB(boxContext: boxContext);
        },
        title: "Export Encrypted Backup",
        description: "Password protected data file",
        icon: appStateSettings["outlinedIcons"]
            ? Icons.enhanced_encryption_outlined
            : Icons.enhanced_encryption_rounded,
      );
    });
  }
}

class ExportDB extends StatelessWidget {
  const ExportDB({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (boxContext) {
      return SettingsContainer(
        onTap: () async {
          await exportDB(boxContext: boxContext);
        },
        title: "export-data-file".tr(),
        icon: appStateSettings["outlinedIcons"]
            ? Icons.upload_outlined
            : Icons.upload_rounded,
      );
    });
  }
}
