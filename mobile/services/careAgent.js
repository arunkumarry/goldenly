import * as SecureStore from "expo-secure-store";
import { refreshSession } from "./auth";

const apiUrl = process.env.EXPO_PUBLIC_API_URL?.replace(/\/$/, "");

function sessionExpiredError() {
  const error = new Error("Your session has ended. Please sign in again.");
  error.code = "SESSION_EXPIRED";
  return error;
}

async function sendRequest(path, body, accessToken, careProfileId) {
  return fetch(`${apiUrl}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${accessToken}`, ...(careProfileId ? { "X-Care-Profile-Id": careProfileId } : {}) },
    body: JSON.stringify(body)
  });
}

async function request(path, body, careProfileId) {
  if (!apiUrl) throw new Error("Set EXPO_PUBLIC_API_URL to your Goldenly API URL before using the care assistant.");
  let accessToken = await SecureStore.getItemAsync("goldenly_access_token");
  let response = await sendRequest(path, body, accessToken, careProfileId);

  if (response.status === 401) {
    const refreshResult = await refreshSession();
    if (!refreshResult.refreshed) {
      if (refreshResult.expired) throw sessionExpiredError();
      throw new Error("Goldenly could not reconnect. Please check your connection and try again.");
    }

    accessToken = await SecureStore.getItemAsync("goldenly_access_token");
    response = await sendRequest(path, body, accessToken, careProfileId);
    if (response.status === 401) throw sessionExpiredError();
  }

  const payload = await response.json();
  if (!response.ok) throw new Error(payload.error || "Goldenly could not complete that request.");
  return payload;
}

export const askCareAgent = (message, careProfileId, conversationToken) => request(
  "/api/v1/care-agent/messages",
  { message, ...(conversationToken ? { conversation_token: conversationToken } : {}) },
  careProfileId
);
export const confirmCareAction = (confirmationToken, shareLocation = false, careProfileId) => request("/api/v1/care-agent/actions/confirm", { confirmation_token: confirmationToken, share_location: shareLocation }, careProfileId);
