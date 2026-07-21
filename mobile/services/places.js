const apiUrl = process.env.EXPO_PUBLIC_API_URL?.replace(/\/$/, "");

async function request(path) {
  if (!apiUrl) throw new Error("Set EXPO_PUBLIC_API_URL to use address search.");
  const response = await fetch(`${apiUrl}${path}`, { headers: { Accept: "application/json" } });
  const payload = await response.json();
  if (!response.ok) throw new Error(payload.error || "Address search is unavailable.");
  return payload;
}

export function searchPlaces(input, sessionToken) {
  return request(`/places/autocomplete?input=${encodeURIComponent(input)}&session_token=${encodeURIComponent(sessionToken)}`);
}

export function getPlace(placeId, sessionToken) {
  return request(`/places/${encodeURIComponent(placeId)}?session_token=${encodeURIComponent(sessionToken)}`);
}
