import * as SecureStore from "expo-secure-store";
import { refreshSession } from "./auth";
import { apiUrl, requireApiUrl } from "./api";

async function send(path, options, careProfileId) {
  const token = await SecureStore.getItemAsync("goldenly_access_token");
  return fetch(`${apiUrl}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...(careProfileId ? { "X-Care-Profile-Id": careProfileId } : {}),
      ...options.headers
    }
  });
}

async function request(path, options, careProfileId) {
  requireApiUrl("Set EXPO_PUBLIC_API_URL to use nearby hospital search.");
  let response = await send(path, options, careProfileId);
  if (response.status === 401) {
    const refreshed = await refreshSession();
    if (!refreshed.refreshed) {
      const error = new Error("Your session has ended. Please sign in again.");
      error.code = "SESSION_EXPIRED";
      throw error;
    }
    response = await send(path, options, careProfileId);
  }
  const payload = await response.json();
  if (!response.ok) throw new Error(payload.error || "Goldenly could not find nearby hospitals.");
  return payload;
}

export const searchNearbyHospitals = (careProfileId, attributes) => request(
  `/api/v1/care_profiles/${careProfileId}/nearby_hospitals`,
  { method: "POST", body: JSON.stringify(attributes) },
  careProfileId
);

export const recordHospitalAction = (searchId, attributes, careProfileId) => request(
  `/api/v1/hospital_searches/${searchId}/actions`,
  { method: "POST", body: JSON.stringify(attributes) },
  careProfileId
);

export const fetchLocationPreference = (careProfileId) => request(`/api/v1/care_profiles/${careProfileId}/location_preference`, { method: "GET" }, careProfileId);
export const updateLocationPreference = (careProfileId, attributes) => request(`/api/v1/care_profiles/${careProfileId}/location_preference`, { method: "PATCH", body: JSON.stringify(attributes) }, careProfileId);
