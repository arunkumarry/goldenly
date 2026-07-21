import { requireOptionalNativeModule } from "expo-modules-core";

const GoldenlyAudioSession = requireOptionalNativeModule("GoldenlyAudioSession");

export function forceSpeakerOutput() {
  GoldenlyAudioSession?.forceSpeakerOutput();
}
