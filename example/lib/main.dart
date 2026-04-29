// Minimal `package:battery_monitor` showcase.
//
// Construct a single `BatteryProvider`, wrap it in a `BatteryState`,
// then bind the composed `Signal<BatteryInfo?>` to a `Watch` widget so
// the UI rebuilds on every native EventChannel emission. There is no
// timer or polling loop -- updates flow from the platform notification
// straight into the widget tree.

import 'package:battery_monitor/battery_monitor.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

void main() {
  runApp(const BatteryMonitorExampleApp());
}

class BatteryMonitorExampleApp extends StatelessWidget {
  const BatteryMonitorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'battery_monitor example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late final BatteryProvider _provider;
  late final BatteryState _state;

  @override
  void initState() {
    super.initState();
    _provider = BatteryProvider();
    _state = BatteryState(_provider);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('battery_monitor example')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Watch((context) {
          final info = _state.batteryInfo.value;
          if (info == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Tile(label: 'Level', value: '${info.level.toStringAsFixed(0)}%'),
              const SizedBox(height: 12),
              _Tile(label: 'Charging state', value: info.chargingState.name),
              const SizedBox(height: 12),
              _Tile(
                label: 'Battery save mode',
                value: info.isInBatterySaveMode ? 'on' : 'off',
              ),
              const Spacer(),
              Watch((context) {
                final errors = _provider.batteryErrors.value;
                if (errors.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent errors (${errors.length})',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        for (final error in errors.take(3))
                          Text(error.toString()),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
