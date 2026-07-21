import * as SecureStore from "expo-secure-store";
import { refreshSession } from "./auth";

const apiUrl = process.env.EXPO_PUBLIC_API_URL?.replace(/\/$/, "");

async function send(path, options, careProfileId) {
  const accessToken = await SecureStore.getItemAsync("goldenly_access_token");
  return fetch(`${apiUrl}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
      ...(careProfileId ? { "X-Care-Profile-Id": careProfileId } : {}),
      ...options.headers
    }
  });
}

async function request(path, options, careProfileId) {
  if (!apiUrl) throw new Error("Set EXPO_PUBLIC_API_URL to your Goldenly API URL.");
  let response = await send(path, options, careProfileId);
  if (response.status === 401) {
    const refreshResult = await refreshSession();
    if (!refreshResult.refreshed) throw new Error("Your session has ended. Please sign in again.");
    response = await send(path, options, careProfileId);
  }
  const payload = await response.json();
  if (!response.ok) throw new Error(payload.error || "Goldenly could not load your care data.");
  return payload;
}

export const fetchDashboard = (careProfileId) => request("/api/v1/dashboard", { method: "GET" }, careProfileId);
export const createServiceRequest = (attributes, careProfileId) => request("/api/v1/service_requests", { method: "POST", body: JSON.stringify(attributes) }, careProfileId);
