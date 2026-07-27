import Constants from "expo-constants";

// EXPO_PUBLIC_API_URL remains useful for local development. Production builds
// use the Cloud Run URL committed in app.json when no local override is set.
const configuredApiUrl = process.env.EXPO_PUBLIC_API_URL || Constants.expoConfig?.extra?.apiUrl;

export const apiUrl = configuredApiUrl?.replace(/\/$/, "");

export function requireApiUrl(message = "Set EXPO_PUBLIC_API_URL to your Goldenly API URL.") {
  if (!apiUrl) throw new Error(message);
  return apiUrl;
}
