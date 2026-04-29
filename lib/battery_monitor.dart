/// Event-driven battery monitoring for Flutter.
///
/// Exposes battery level, charging state, and power-save mode as
/// `ValueListenable`s backed by native EventChannels on Android and
/// iOS. All updates are push-based -- there is no polling loop in
/// either the Dart layer or the native handlers.
///
/// The public surface is the [BatteryProvider] / [BatteryState] pair
/// plus the three [BatteryLevelChannel], [BatteryStateChannel], and
/// [BatterySaveModeChannel] wrappers. Each accepts an optional
/// `eventStream` for unit tests, so consumers can exercise reactive
/// behaviour without a platform binding.
library;

export 'src/battery_provider.dart';
export 'src/battery_state.dart';
export 'src/models/battery_info.dart';
export 'src/platform/battery_level_channel.dart';
export 'src/platform/battery_save_mode_channel.dart';
export 'src/platform/battery_state_channel.dart';
