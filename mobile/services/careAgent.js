import * as SecureStore from "expo-secure-store";

const apiUrl = process.env.EXPO_PUBLIC_API_URL?.replace(/\/$/, "");

async function request(path, body) {
  if (!apiUrl) throw new Error("Set EXPO_PUBLIC_API_URL to your Goldenly API URL before using the care assistant.");
  const accessToken = await SecureStore.getItemAsync("goldenly_access_token");
  const response = await fetch(`${apiUrl}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify(body)
  });
  const payload = await response.json();
  if (!response.ok) throw new Error(payload.error || "Goldenly could not complete that request.");
  return payload;
}

export const askCareAgent = (message) => request("/api/v1/care-agent/messages", { message });
export const confirmCareAction = (confirmationToken, shareLocation = false) => request("/api/v1/care-agent/actions/confirm", { confirmation_token: confirmationToken, share_location: shareLocation });
