require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name = 'GoldenlyAudioSession'
  s.version = package['version']
  s.summary = 'Goldenly iOS speaker routing control.'
  s.description = 'Routes Goldenly voice responses through the iOS media speaker session.'
  s.license = 'MIT'
  s.author = 'Goldenly'
  s.homepage = 'https://goldenlyai.com'
  s.platforms = { :ios => '15.1' }
  s.swift_version = '5.9'
  s.source = { git: 'https://goldenlyai.com' }
  s.static_framework = true
  s.dependency 'ExpoModulesCore'
  s.source_files = '**/*.{h,m,swift}'
end
