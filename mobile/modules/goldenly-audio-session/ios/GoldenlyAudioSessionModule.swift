import AVFAudio
import ExpoModulesCore

public final class GoldenlyAudioSessionModule: Module {
  public func definition() -> ModuleDefinition {
    Name("GoldenlyAudioSession")

    Function("forceSpeakerOutput") {
      let audioSession = AVAudioSession.sharedInstance()

      try audioSession.setCategory(
        .playback,
        mode: .spokenAudio,
        options: [.duckOthers]
      )
      try audioSession.setActive(true)
    }
  }
}
