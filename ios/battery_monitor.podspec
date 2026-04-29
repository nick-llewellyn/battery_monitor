Pod::Spec.new do |s|
  s.name             = 'battery_monitor'
  s.version          = '1.0.0'
  s.summary          = 'Event-driven battery monitoring for Flutter on Android and iOS.'
  s.description      = <<-DESC
Battery level, charging state, and Low Power Mode delivered via native
EventChannels. Event-driven on both platforms (no polling).
                       DESC
  s.homepage         = 'https://github.com/nick-llewellyn/battery_monitor'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Nicholas Llewellyn' => 'nllewelln@gmail.com' }
  s.source           = { :path => '.' }
  # Sources live under battery_monitor/Sources/battery_monitor/ to share a
  # single source tree with Package.swift (Swift Package Manager).
  s.source_files     = 'battery_monitor/Sources/battery_monitor/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'

  # Flutter.framework does not contain an i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
end
