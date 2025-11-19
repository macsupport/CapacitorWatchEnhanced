Pod::Spec.new do |s|
  s.name             = 'VetcalculatorsCapacitorWatch'          # <-- MUST match Podfile
  s.version          = '1.0.0'
  s.summary          = 'Capacitor watch connectivity plugin'
  s.license          = 'MIT'
  s.homepage         = 'https://example.com'
  s.author           = { 'Mike' => 'you@example.com' }

  # This podspec is at the monorepo root: plugins/capacitor-watch
  # The actual iOS plugin code lives under packages/capacitor-plugin/ios/Plugin
  s.source           = { :path => '.' }

  s.ios.deployment_target = '13.0'
  s.swift_version         = '5.7'

  # iOS native code
  s.source_files = 'packages/capacitor-plugin/ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp}'

  s.static_framework = true

  # Capacitor dependency
  s.dependency 'Capacitor'
  s.dependency 'CapacitorBackgroundRunner'
end