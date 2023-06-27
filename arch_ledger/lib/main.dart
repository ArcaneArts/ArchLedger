import 'dart:async';

import 'package:arch_ledger/service/test_service.dart';
import 'package:arch_ledger/util.dart';
import 'package:flutter/cupertino.dart';

void main() => runZonedGuarded(
    () => init().then((value) => runApp(const ArchLedger())),
    (error, stack) {});

Future<void> init() async {
  await initializeLogging();
  registerServices();
  await services().waitForStartup();
}

void registerServices() {
  services().register(() => TestService(), lazy: false);
}

class ArchLedger extends StatefulWidget {
  const ArchLedger({Key? key}) : super(key: key);

  @override
  State<ArchLedger> createState() => _ArchLedgerState();
}

class _ArchLedgerState extends State<ArchLedger> {
  @override
  Widget build(BuildContext context) => CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: "Arch Ledger",
        home: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text("Title Or.,.."),
          ),
          child: Text("Derp"),
        ),
      );
}
