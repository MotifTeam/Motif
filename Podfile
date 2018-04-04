# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Motif' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Motif
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'TransitionButton'
  pod 'AudioKit'
  pod 'PianoView'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    # add this line
    target.new_shell_script_build_phase.shell_script = "mkdir -p $PODS_CONFIGURATION_BUILD_DIR/#{target.name}"
    target.build_configurations.each do |config|
      config.build_settings['CONFIGURATION_BUILD_DIR'] = '$PODS_CONFIGURATION_BUILD_DIR'
    end
  end
end
