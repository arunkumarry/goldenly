import * as SecureStore from "expo-secure-store";

const apiUrl = process.env.EXPO_PUBLIC_API_URL?.replace(/\/$/, "");

async function request(path, body) {
  if (!apiUrl) throw new Error("Set EXPO_PUBLIC_API_URL to your Goldenly API URL before signing in.");
  const response = await fetch(`${apiUrl}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  const payload = await response.json();
  if (!response.ok) throw new Error(payload.error || "Something went wrong. Please try again.");
  return payload;
}

export const requestCode = (identifier) => request("/api/v1/auth/request-code", { identifier });
export const signIn = (identifier, code) => request("/api/v1/auth/sign-in", { identifier, code });
export const signUp = (payload) => request("/api/v1/auth/sign-up", payload);

export async function saveSession(user, tokens) {
  await SecureStore.setItemAsync("goldenly_access_token", tokens.access_token);
  await SecureStore.setItemAsync("goldenly_refresh_token", tokens.refresh_token);
  await SecureStore.setItemAsync("goldenly_user", JSON.stringify(user));
}

export async function getSession() {
  const user = await SecureStore.getItemAsync("goldenly_user");
  return user ? JSON.parse(user) : null;
}

export async function clearTokens() {
  await SecureStore.deleteItemAsync("goldenly_access_token");
  await SecureStore.deleteItemAsync("goldenly_refresh_token");
  await SecureStore.deleteItemAsync("goldenly_user");
}
