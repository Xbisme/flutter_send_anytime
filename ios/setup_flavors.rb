#!/usr/bin/env ruby
# Adds dev/prod flavor build configurations + shared schemes to Runner.xcodeproj.
# Each flavor configuration uses its own xcconfig (ios/Flutter/<Mode>-<flavor>.xcconfig)
# which includes the matching CocoaPods config + Generated.xcconfig and sets the
# flavor bundle id + display name. Idempotent: re-running strips prior flavor
# configs/schemes first.
require 'xcodeproj'

PROJECT_PATH = File.join(__dir__, 'Runner.xcodeproj')
FLAVORS = {
  'dev'  => { bundle: 'app.safesend.dev', display: 'Safe Send Dev' },
  'prod' => { bundle: 'app.safesend',     display: 'Safe Send' },
}.freeze
BASE_MODES = %w[Debug Release Profile].freeze

proj = Xcodeproj::Project.open(PROJECT_PATH)
runner = proj.targets.find { |t| t.name == 'Runner' }
tests  = proj.targets.find { |t| t.name == 'RunnerTests' }
raise 'Runner target not found' unless runner

debug_ref = proj.files.find { |f| f.path && f.path.end_with?('Debug.xcconfig') }
flutter_group = debug_ref.parent

def ensure_ref(group, proj, filename)
  rel = "Flutter/#{filename}"
  proj.files.find { |f| f.path == rel } ||
    group.new_reference(File.join(__dir__, 'Flutter', filename))
end

# --- Remove any pre-existing flavor configs (idempotency) ---
flavor_suffixes = FLAVORS.keys.map { |f| "-#{f}" }
[proj, runner, tests].compact.each do |obj|
  list = obj.build_configuration_list
  list.build_configurations.dup.each do |c|
    if flavor_suffixes.any? { |s| c.name.end_with?(s) }
      list.build_configurations.delete(c)
      c.remove_from_project
    end
  end
end

def add_config(obj, proj, mode, flavor, base_ref, extra = {})
  list = obj.build_configuration_list
  base = list.build_configurations.find { |c| c.name == mode }
  return unless base

  cfg = proj.new(Xcodeproj::Project::Object::XCBuildConfiguration)
  cfg.name = "#{mode}-#{flavor}"
  cfg.build_settings = base.build_settings.dup
  cfg.base_configuration_reference = base_ref if base_ref
  extra.each { |k, v| cfg.build_settings[k] = v }
  list.build_configurations << cfg
end

FLAVORS.each do |flavor, info|
  bundle = info[:bundle]
  BASE_MODES.each do |mode|
    ref = ensure_ref(flutter_group, proj, "#{mode}-#{flavor}.xcconfig")
    # Runner: xcconfig pulls Pods + Generated + APP_DISPLAY_NAME; the bundle id
    # is pinned in build settings (the base config's value would otherwise
    # override the xcconfig). Display name is supplied by the xcconfig.
    add_config(runner, proj, mode, flavor, ref,
               'PRODUCT_BUNDLE_IDENTIFIER' => bundle)
    # Project base settings: inherit (no Pods/flavor xcconfig needed).
    add_config(proj, proj, mode, flavor, nil)
    # Tests: matching test bundle id; inherits search paths from the host.
    if tests
      add_config(tests, proj, mode, flavor, nil,
                 'PRODUCT_BUNDLE_IDENTIFIER' => "#{bundle}.RunnerTests")
    end
  end
end

proj.save

# --- Shared schemes named exactly after each flavor ---
FLAVORS.each_key do |flavor|
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(runner)
  scheme.set_launch_target(runner) if scheme.respond_to?(:set_launch_target)

  scheme.build_action.entries.first.build_for_running = true
  scheme.launch_action.build_configuration  = "Debug-#{flavor}"
  scheme.test_action.build_configuration     = "Debug-#{flavor}"
  scheme.analyze_action.build_configuration   = "Debug-#{flavor}"
  scheme.profile_action.build_configuration   = "Profile-#{flavor}"
  scheme.archive_action.build_configuration   = "Release-#{flavor}"

  scheme.save_as(PROJECT_PATH, flavor, true)
end

puts "OK: added #{FLAVORS.keys.join('/')} configs (per-mode xcconfig) + schemes"
