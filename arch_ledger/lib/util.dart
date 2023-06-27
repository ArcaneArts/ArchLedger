import 'package:fast_log/fast_log.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:precision_stopwatch/precision_stopwatch.dart';

enum ArcaneServiceState {
  offline,
  online,
  starting,
  stopping,
  failed,
}

typedef ArcaneServiceConstructor<T extends ArcaneService> = T Function();

ArcaneServiceProvider? _serviceProvider;

Box? serviceBox;

ArcaneServiceProvider services() {
  _serviceProvider ??= ArcaneServiceProvider._createStandard();
  return _serviceProvider!;
}

class ArcaneServiceProvider {
  List<Future<void>> tasks = [];
  Map<Type, ArcaneService> services = {};
  Map<Type, ArcaneServiceConstructor<dynamic>> constructors = {};

  ArcaneServiceProvider._();

  Future<void> waitForStartup() =>
      Future.wait(tasks).then((value) => tasks = []);

  factory ArcaneServiceProvider._createStandard() {
    ArcaneServiceProvider provider = ArcaneServiceProvider._();
    return provider;
  }

  void register<T extends ArcaneService>(
      ArcaneServiceConstructor<T> constructor,
      {bool lazy = true}) {
    constructors.putIfAbsent(T, () => constructor);
    verbose("Registered Service $T");
    if (!lazy) {
      verbose("Auto-starting Service $T");
      get<T>();
    }
  }

  T get<T extends ArcaneService>() {
    T t = getQuiet();

    if (t.state == ArcaneServiceState.offline ||
        t.state == ArcaneServiceState.failed) {
      t.startService();
    }

    return t;
  }

  T getQuiet<T extends ArcaneService>() {
    if (!services.containsKey(T)) {
      if (!constructors.containsKey(T)) {
        throw Exception("No service registered for type $T");
      }

      services.putIfAbsent(T, () => constructors[T]!());
    }

    return services[T] as T;
  }
}

abstract class ArcaneService {
  ArcaneServiceState _state = ArcaneServiceState.offline;
  ArcaneServiceState get state => _state;
  String get name => runtimeType.toString().replaceAll("Service", "");

  void restartService() {
    PrecisionStopwatch p = PrecisionStopwatch.start();
    verbose("Restarting $name Service");
    stopService();
    startService();
    verbose("Restarted $name Service in ${p.getMilliseconds()}ms");
  }

  void startService() {
    if (!(_state == ArcaneServiceState.offline ||
        _state == ArcaneServiceState.failed)) {
      throw Exception("$name Service cannot be started while $state");
    }

    PrecisionStopwatch p = PrecisionStopwatch.start();
    _state = ArcaneServiceState.starting;
    verbose("Starting $name Service");

    try {
      if (this is AsyncStartupTasked) {
        PrecisionStopwatch px = PrecisionStopwatch.start();
        verbose("Queued Startup Task: $name");
        services()
            .tasks
            .add((this as AsyncStartupTasked).onStartupTask().then((value) {
              success(
                  "Completed $name Startup Task in ${px.getMilliseconds()}ms");
            }));
      }

      onStart();
      _state = ArcaneServiceState.online;
    } catch (e, es) {
      _state = ArcaneServiceState.failed;
      error("Failed to start $name Service: $e");
      error(es);
    }

    if (_state == ArcaneServiceState.starting) {
      _state = ArcaneServiceState.failed;
    }

    if (_state == ArcaneServiceState.failed) {
      warn(
          "Failed to start $name Service! It will be offline until you restart the app or the service is re-requested.");
    } else {
      success("Started $name Service in ${p.getMilliseconds()}ms");
    }
  }

  void stopService() {
    if (!(_state == ArcaneServiceState.online)) {
      throw Exception("$name Service cannot be stopped while $state");
    }

    PrecisionStopwatch p = PrecisionStopwatch.start();
    _state = ArcaneServiceState.stopping;
    verbose("Stopping $name Service");

    try {
      onStop();
      _state = ArcaneServiceState.offline;
    } catch (e, es) {
      _state = ArcaneServiceState.offline;
      error("Failed while stopping $name Service: $e");
      error(es);
    }

    if (_state == ArcaneServiceState.failed) {
      warn("Failed to stop $name Service! It is still marked as offline.");
    } else {
      success("Stopped $name Service in ${p.getMilliseconds()}ms");
    }
  }

  void onStart();

  void onStop();
}

abstract class AsyncStartupTasked {
  Future<void> onStartupTask();
}

abstract class ArcaneStatelessService extends ArcaneService {
  @override
  void onStart() {}

  @override
  void onStop() {}
}

Future<void> initializeLogging() async {
  lDebugMode = true;
}

NumberFormat _money = NumberFormat.simpleCurrency(decimalDigits: 2);

extension XInt on int {
  double money() => this * 0.01;

  String moneyString() => _money.format(money());
}

extension XDouble on double {
  int moneyInt() => (this * 100).toInt();

  String moneyString() => _money.format(this);
}
