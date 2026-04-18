import 'dart:async';
import 'dart:typed_data';
import 'package:async/async.dart';
import 'dart:convert';
import 'package:budget/database/binary_string_conversion.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/accountAndBackup.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/util/debouncer.dart';
import 'package:budget/widgets/walletEntry.dart';
// import 'package:drift/web.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:googleapis/drive/v3.dart' as drive;
import 'dart:io';

bool isSyncBackupFile(String? backupFileName) {
  if (backupFileName == null) return false;
  return backupFileName.contains("sync-");
}

bool isCurrentDeviceSyncBackupFile(String? backupFileName) {
  if (backupFileName == null) return false;
  return backupFileName == getCurrentDeviceSyncBackupFileName();
}

String getCurrentDeviceSyncBackupFileName({String? clientIDForSync}) {
  if (clientIDForSync == null) clientIDForSync = clientID;
  return "sync-" + clientIDForSync + ".sqlite";
}

String getDeviceFromSyncBackupFileName(String? backupFileName) {
  if (backupFileName == null) return "";
  return (backupFileName).replaceAll("sync-", "").split("-")[0];
}

String getCurrentDeviceName() {
  return (clientID).split("-")[0];
}

Future<DateTime> getDateOfLastSyncedWithClient(String clientIDForSync) async {
  String string =
      sharedPreferences.getString("dateOfLastSyncedWithClient") ?? "{}";
  String lastTimeSynced =
      (jsonDecode(string)[clientIDForSync] ?? "").toString();
  if (lastTimeSynced == "") return DateTime(0);
  try {
    return DateTime.parse(lastTimeSynced);
  } catch (e) {
    print("Error getting time of last sync " + e.toString());
    return DateTime(0);
  }
}

Future<bool> setDateOfLastSyncedWithClient(
    String clientIDForSync, DateTime dateTimeSynced) async {
  String string =
      sharedPreferences.getString("dateOfLastSyncedWithClient") ?? "{}";
  dynamic parsed = jsonDecode(string);
  parsed[clientIDForSync] = dateTimeSynced.toString();
  await sharedPreferences.setString(
      "dateOfLastSyncedWithClient", jsonEncode(parsed));
  return true;
}

// if changeMadeSync show loading and check if syncEveryChange is turned on
Timer? syncTimeoutTimer;
Debouncer backupDebounce = Debouncer(milliseconds: 5000);
Future<bool> createSyncBackup(
    {bool changeMadeSync = false,
    bool changeMadeSyncWaitForDebounce = true}) async {
  if (appStateSettings["hasSignedIn"] == false) return false;
  if (errorSigningInDuringCloud == true) return false;
  if (appStateSettings["backupSync"] == false) return false;
  if (changeMadeSync == true && appStateSettings["syncEveryChange"] == false)
    return false;
  // create the auto syncs after 10 seconds of no changes
  if (changeMadeSync == true &&
      (appStateSettings["syncEveryChange"] == true && kIsWeb) &&
      changeMadeSyncWaitForDebounce == true) {
    print("Running sync debouncer");
    backupDebounce.run(() {
      createSyncBackup(
          changeMadeSync: true, changeMadeSyncWaitForDebounce: false);
    });
  }

  print("Creating sync backup");
  if (changeMadeSync)
    loadingIndeterminateKey.currentState?.setVisibility(true, opacity: 0.4);
  if (syncTimeoutTimer?.isActive == true) {
    // openSnackbar(SnackbarMessage(title: "Please wait..."));
    if (changeMadeSync)
      loadingIndeterminateKey.currentState?.setVisibility(false);
    return false;
  } else {
    syncTimeoutTimer = Timer(Duration(milliseconds: 5000), () {
      syncTimeoutTimer!.cancel();
    });
  }

  bool hasSignedIn = false;
  if (googleUser == null) {
    hasSignedIn = await signInGoogle(
      gMailPermissions: false,
      waitForCompletion: false,
      silentSignIn: true,
    );
  } else {
    hasSignedIn = true;
  }
  if (hasSignedIn == false) {
    if (changeMadeSync)
      loadingIndeterminateKey.currentState?.setVisibility(false);
    return false;
  }

  final authHeaders = await googleUser!.authHeaders;
  final authenticateClient = GoogleAuthClient(authHeaders);
  drive.DriveApi driveApi = drive.DriveApi(authenticateClient);
  if (driveApi == null) {
    if (changeMadeSync)
      loadingIndeterminateKey.currentState?.setVisibility(false);
    throw "Failed to login to Google Drive";
  }

  drive.FileList fileList = await driveApi.files.list(
      spaces: 'appDataFolder', $fields: 'files(id, name, modifiedTime, size)');
  List<drive.File>? files = fileList.files;

  for (drive.File file in files ?? []) {
    if (isCurrentDeviceSyncBackupFile(file.name)) {
      try {
        await deleteBackup(driveApi, file.id ?? "");
      } catch (e) {
        print(e.toString());
      }
    }
  }
  await createBackup(null,
      silentBackup: true, deleteOldBackups: true, clientIDForSync: clientID);
  if (changeMadeSync)
    loadingIndeterminateKey.currentState?.setVisibility(false);
  return true;
}

class SyncLog {
  SyncLog({
    this.deleteLogType,
    this.updateLogType,
    required this.transactionDateTime,
    required this.pk,
    this.itemToUpdate,
  });

  DeleteLogType? deleteLogType;
  UpdateLogType? updateLogType;
  DateTime? transactionDateTime;
  String pk;
  dynamic itemToUpdate;

  @override
  String toString() {
    return "SyncLog(deleteLogType: $deleteLogType, updateLogType: $updateLogType, transactionDateTime: $transactionDateTime, pk: $pk, itemToUpdate: $itemToUpdate)";
  }
}

/// Holds all 9 query results so they can be passed to a background isolate.
/// All fields are plain Dart data classes (Drift-generated) — safely copyable
/// across isolate boundaries without serialization.
class _SyncLogsInput {
  final List<TransactionWallet> wallets;
  final List<TransactionCategory> categories;
  final List<Budget> budgets;
  final List<CategoryBudgetLimit> categoryBudgetLimits;
  final List<Transaction> transactions;
  final List<TransactionAssociatedTitle> titles;
  final List<ScannerTemplate> scannerTemplates;
  final List<Objective> objectives;
  final List<DeleteLog> deleteLogs;

  _SyncLogsInput({
    required this.wallets,
    required this.categories,
    required this.budgets,
    required this.categoryBudgetLimits,
    required this.transactions,
    required this.titles,
    required this.scannerTemplates,
    required this.objectives,
    required this.deleteLogs,
  });
}

/// Top-level function — executed in a background isolate via compute().
/// Converts raw query results into SyncLog entries without touching the DB or UI.
List<SyncLog> _buildSyncLogsIsolate(_SyncLogsInput input) {
  final List<SyncLog> logs = [];
  for (final e in input.wallets) {
    logs.add(SyncLog(
      deleteLogType: null,
      updateLogType: UpdateLogType.TransactionWallet,
      pk: e.walletPk,
      itemToUpdate: e,
      transactionDateTime: e.dateTimeModified,
    ));
  }
  for (final e in input.categories) {
    logs.add(SyncLog(
      deleteLogType: null,
      updateLogType: UpdateLogType.TransactionCategory,
      pk: e.categoryPk,
      itemToUpdate: e,
      transactionDateTime: e.dateTimeModified,
    ));
  }
  for (final e in input.budgets) {
    logs.add(SyncLog(
      deleteLogType: null,
      updateLogType: UpdateLogType.Budget,
      pk: e.budgetPk,
      itemToUpdate: e,
      transactionDateTime: e.dateTimeModified,
    ));
  }
  for (final e in input.categoryBudgetLimits) {
    logs.add(SyncLog(
      deleteLogType: null,
      updateLogType: UpdateLogType.CategoryBudgetLimit,
      pk: e.categoryLimitPk,
      itemToUpdate: e,
      transactionDateTime: e.dateTimeModified,
    ));
  }
  for (final e in input.transactions) {
    logs.add(SyncLog(
      deleteLogType: null,
      updateLogType: UpdateLogType.Transaction,
      pk: e.transactionPk,
      itemToUpdate: e,
      transactionDateTime: e.dateTimeModified,
    ));
  }
  for (final e in input.titles) {
    logs.add(SyncLog(
      deleteLogType: null,
      updateLogType: UpdateLogType.TransactionAssociatedTitle,
      pk: e.associatedTitlePk,
      itemToUpdate: e,
      transactionDateTime: e.dateTimeModified,
    ));
  }
  for (final e in input.scannerTemplates) {
    logs.add(SyncLog(
      deleteLogType: null,
      updateLogType: UpdateLogType.ScannerTemplate,
      pk: e.scannerTemplatePk,
      itemToUpdate: e,
      transactionDateTime: e.dateTimeModified,
    ));
  }
  for (final e in input.objectives) {
    logs.add(SyncLog(
      deleteLogType: null,
      updateLogType: UpdateLogType.Objective,
      pk: e.objectivePk,
      itemToUpdate: e,
      transactionDateTime: e.dateTimeModified,
    ));
  }
  for (final e in input.deleteLogs) {
    logs.add(SyncLog(
      deleteLogType: e.type,
      updateLogType: null,
      pk: e.entryPk,
      transactionDateTime: e.dateTimeModified,
    ));
  }
  return logs;
}

// Only allow one sync at a time
bool canSyncData = true;

bool requestSyncDataCancel = false;

CancelableCompleter<bool> syncDataCompleter = CancelableCompleter(onCancel: () {
  requestSyncDataCancel = true;
});

Future<dynamic> cancelAndPreventSyncOperation() async {
  requestSyncDataCancel = true;
  return await syncDataCompleter.operation.cancel();
}

Future<bool> runForceSignIn(BuildContext context) async {
  if (appStateSettings["forceAutoLogin"] == false) return false;
  if (appStateSettings["hasSignedIn"] == false) return false;
  return await signInGoogle(
    gMailPermissions: false,
    waitForCompletion: false,
    silentSignIn: true,
    context: context,
  );
}

Future<bool> syncData(BuildContext context) async {
  // Create a new instance of the completer
  if (syncDataCompleter.isCompleted) {
    syncDataCompleter = CancelableCompleter(onCancel: () {
      requestSyncDataCancel = true;
    });
  }

  syncDataCompleter.complete(Future.value(_syncData(context)));
  return syncDataCompleter.operation.value;
}

// load the latest backup and import any newly modified data into the db
Future<bool> _syncData(BuildContext context) async {
  if (canSyncData == false) return false;
  // Syncing data seems to fail on iOS debug mode (at least on iPad).
  // When actually creating the entries, it seems the device disconnects.
  // It works on release though.

  if (appStateSettings["backupSync"] == false) return false;
  if (appStateSettings["hasSignedIn"] == false) return false;
  if (errorSigningInDuringCloud == true) return false;

  // We only want to prevent this if silent sign in, otherwise we can show the user the google login popup every time on web?
  // Prevent sign-in on web - background sign-in cannot access Google Drive etc.
  if (kIsWeb &&
      !entireAppLoaded &&
      appStateSettings["webForceLoginPopupOnLaunch"] != true) return false;

  canSyncData = false;

  bool hasSignedIn = false;
  if (googleUser == null) {
    hasSignedIn = await signInGoogle(
      gMailPermissions: false,
      waitForCompletion: false,
      silentSignIn: true,
    );
  } else {
    hasSignedIn = true;
  }
  if (hasSignedIn == false) {
    canSyncData = true;
    return false;
  }

  final authHeaders = await googleUser!.authHeaders;
  final authenticateClient = GoogleAuthClient(authHeaders);
  drive.DriveApi driveApi = drive.DriveApi(authenticateClient);
  if (driveApi == null) {
    throw "Failed to login to Google Drive";
  }

  // Run backup upload and Drive file listing in parallel — they are independent
  // network operations that each create their own DriveApi client internally.
  // ignore: unawaited_futures
  createSyncBackup();

  drive.FileList fileList = await driveApi.files.list(
      spaces: 'appDataFolder', $fields: 'files(id, name, modifiedTime, size)');
  List<drive.File>? files = fileList.files;

  if (files == null) {
    throw "No backups found.";
  }

  List<drive.File> filesToDownloadSyncChanges = [];
  for (drive.File file in files) {
    if (isSyncBackupFile(file.name)) {
      filesToDownloadSyncChanges.add(file);
    }
  }

  print("LOADING SYNC DB");
  DateTime syncStarted = DateTime.now();
  List<SyncLog> syncLogs = [];
  List<drive.File> filesSyncing = [];

  int currentFileIndex = 0;
  loadingProgressKey.currentState?.setProgressPercentage(0);
  for (drive.File file in filesToDownloadSyncChanges) {
    if (requestSyncDataCancel == true) {
      loadingProgressKey.currentState?.setProgressPercentage(0);
      loadingIndeterminateKey.currentState?.setVisibility(false);
      print("Cancelling sync!");
      requestSyncDataCancel = false;
      return false;
    }

    loadingIndeterminateKey.currentState?.setVisibility(true);

    // we don't want to restore this clients backup
    if (isCurrentDeviceSyncBackupFile(file.name)) continue;

    // check if this is a new sync from this specific client
    DateTime lastSynced = await getDateOfLastSyncedWithClient(
        getDeviceFromSyncBackupFileName(file.name));

    print("COMPARING TIMES");
    print(file.modifiedTime?.toLocal());
    print(lastSynced);
    print(lastSynced != file.modifiedTime!.toLocal());
    if (file.modifiedTime == null ||
        lastSynced.isAfter(file.modifiedTime!.toLocal()) ||
        lastSynced == file.modifiedTime!.toLocal()) {
      print(
          "no need to restore backup from this client, no new backup file to pull data from");
      continue;
    }

    String? fileId = file.id;
    if (fileId == null) continue;
    print("SYNCING WITH " + (file.name ?? ""));
    filesSyncing.add(file);

    // BytesBuilder is faster than List.insertAll for accumulating streamed chunks
    final builder = BytesBuilder(copy: false);
    dynamic response = await driveApi.files
        .get(fileId, downloadOptions: drive.DownloadOptions.fullMedia);
    await for (final data in response.stream) {
      builder.add(data);
    }
    final Uint8List dataStore = builder.toBytes();

    FinanceDatabase databaseSync;

    if (kIsWeb) {
      String dataEncoded = bin2str.encode(dataStore);

      try {
        databaseSync = await constructDb('syncdb', initialDataWeb: dataStore);
      } catch (e) {
        double megabytes = dataEncoded.length / (1024 * 1024);
        await openPopup(
          context,
          title: "syncing-failed".tr(),
          description: e.toString() +
              "\n\n" +
              megabytes.toString() +
              " MB in size" +
              " when syncing with " +
              file.name.toString(),
          icon: appStateSettings["outlinedIcons"]
              ? Icons.sync_problem_outlined
              : Icons.sync_problem_rounded,
          onSubmit: () {
            popRoute(context);
          },
          onSubmitLabel: "ok".tr(),
        );
        // final html.Storage localStorage = html.window.localStorage;
        // localStorage["moor_db_str_syncdb"] = "";
        throw (e);
      }
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'syncdb.sqlite'));
      await dbFile.writeAsBytes(dataStore);
      databaseSync = await constructDb('syncdb');
    }

    try {
      // Run all 9 table queries in parallel — Drift's MultiExecutor has a
      // separate read executor so concurrent reads don't block each other.
      final queryResults = await Future.wait([
        databaseSync.getAllNewWallets(lastSynced),
        databaseSync.getAllNewCategories(lastSynced),
        databaseSync.getAllNewBudgets(lastSynced),
        databaseSync.getAllNewCategoryBudgetLimits(lastSynced),
        databaseSync.getAllNewTransactions(lastSynced),
        databaseSync.getAllNewAssociatedTitles(lastSynced),
        databaseSync.getAllNewScannerTemplates(lastSynced),
        databaseSync.getAllNewObjectives(lastSynced),
        databaseSync.getAllNewDeleteLogs(lastSynced),
      ]);

      // Build SyncLog objects in a background isolate — pure Dart iteration,
      // no DB or UI access needed.
      final List<SyncLog> newSyncLogs = await compute(
        _buildSyncLogsIsolate,
        _SyncLogsInput(
          wallets: queryResults[0] as List<TransactionWallet>,
          categories: queryResults[1] as List<TransactionCategory>,
          budgets: queryResults[2] as List<Budget>,
          categoryBudgetLimits:
              queryResults[3] as List<CategoryBudgetLimit>,
          transactions: queryResults[4] as List<Transaction>,
          titles: queryResults[5] as List<TransactionAssociatedTitle>,
          scannerTemplates: queryResults[6] as List<ScannerTemplate>,
          objectives: queryResults[7] as List<Objective>,
          deleteLogs: queryResults[8] as List<DeleteLog>,
        ),
      );
      syncLogs.addAll(newSyncLogs);

      print("SYNC QUERY COUNTS: "
          "wallets=${(queryResults[0] as List).length}, "
          "categories=${(queryResults[1] as List).length}, "
          "transactions=${(queryResults[4] as List).length}, "
          "deleteLogs=${(queryResults[8] as List).length}");
    } catch (e) {
      print("Syncing error and failed: " + e.toString());
      filesSyncing.remove(file);
      await databaseSync.close();
      loadingProgressKey.currentState?.setProgressPercentage(1);
      canSyncData = true;
      await openPopup(
        context,
        title: "syncing-failed".tr(),
        description: "sync-fail-reason".tr() + "\n\n" + file.name.toString(),
        descriptionWidget: Padding(
          padding: const EdgeInsetsDirectional.only(top: 8, bottom: 12),
          child: CodeBlock(text: e.toString()),
        ),
        icon: appStateSettings["outlinedIcons"]
            ? Icons.sync_problem_outlined
            : Icons.sync_problem_rounded,
        onCancel: () {
          popRoute(context);
        },
        onCancelLabel: "close".tr(),
        onSubmit: () {
          chooseBackup(context, isManaging: true, isClientSync: true);
        },
        onSubmitLabel: "manage".tr(),
      );
      // By returning we do not update the time last synced!
      return false;
    }

    currentFileIndex = currentFileIndex + 1;
    loadingProgressKey.currentState?.setProgressPercentage(
        currentFileIndex / filesToDownloadSyncChanges.length);

    await databaseSync.close();
  }

  // Yield to the frame scheduler before the heavy batch write so Flutter
  // can paint at least one frame between sync and DB commit.
  await Future.delayed(Duration.zero);
  await database.processSyncLogs(syncLogs);
  for (drive.File file in filesSyncing)
    setDateOfLastSyncedWithClient(getDeviceFromSyncBackupFileName(file.name),
        file.modifiedTime?.toLocal() ?? DateTime(0));

  try {
    print("UPDATED WALLET CURRENCY");
    await database.getWalletInstance(appStateSettings["selectedWalletPk"]);
  } catch (e) {
    print("Selected wallet not found: " + e.toString());
    await setPrimaryWallet((await database.getAllWallets())[0].walletPk);
  }

  updateSettings(
    "lastSynced",
    syncStarted.toString(),
    pagesNeedingRefresh: [],
    updateGlobalState: getIsFullScreen(context) ? true : false,
  );

  loadingProgressKey.currentState?.setProgressPercentage(0.999);

  Future.delayed(Duration(milliseconds: 300), () {
    loadingProgressKey.currentState?.setProgressPercentage(1);
  });

  canSyncData = true;

  print("DONE SYNCING");
  return true;
}
