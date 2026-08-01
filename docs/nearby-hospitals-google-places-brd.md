# Goldenly Nearby Hospitals BRD

## 1. Purpose

Goldenly Nearby Hospitals helps a member, elder, family coordinator, or authorised trusted contact find hospitals close to the active Care Profile’s location. The feature is available on the Goldenly web dashboard and the Goldenly mobile app.

The feature uses Google Places API for factual place discovery and presents a small, accessible hospital list with **Call** and **Directions** actions. It does not diagnose, determine the most clinically appropriate hospital, verify real-time emergency capacity, dispatch an ambulance, or notify a hospital.

## 2. Product principles

- **Location is consented:** Goldenly requests precise location only when needed and explains why it is being used.
- **The active care profile is explicit:** A coordinator must always see whose location and hospital results they are viewing.
- **Facts, not clinical recommendations:** Results are described as nearby options, not as “best” or medically suitable choices.
- **Human action is required:** Call and directions actions require an intentional user interaction; no automatic calls are placed.
- **Emergency-first behaviour:** For a user-selected SOS event, emergency-service calling takes priority over browsing a hospital list.
- **Accessible by default:** Large touch targets, high contrast, screen-reader labels, localisation, and voice-compatible summaries are required.

## 3. Scope

### 3.1 In scope

- Hospital list based on the current device location, a saved care address, or a manually selected location.
- Google Places Nearby Search integration for hospital discovery.
- Result cards with name, approximate distance, address, open/closed status when available, phone number when available, and map link.
- Call and Directions actions on web and mobile.
- Country-aware operation for India and the United States.
- Location permission, fallback, privacy, error, and no-results flows.
- Audit record for user-initiated hospital searches and call/directions actions.
- Voice-agent handoff to this hospital finder after the user asks for hospital information.

### 3.2 Out of scope

- Medical advice, diagnosis, triage, or a claim that a hospital is clinically appropriate.
- Ambulance dispatch, automatic calling of emergency services, or automatic hospital notification.
- Real-time emergency-room capacity, bed availability, wait times, insurance acceptance, or specialist availability unless a separately verified partner data source is introduced.
- Hospital appointment booking.
- Persisting a general-purpose Google hospital directory outside what is allowed by Google Maps Platform terms.
- Routing calculations beyond opening the selected location in Google Maps/directions; a future Routes API feature may provide travel estimates.

## 4. User roles

| Role | Hospital-finder access |
| --- | --- |
| Care-profile owner / elder | Search hospitals near their current or saved location. |
| Family coordinator | Search hospitals for a selected Care Profile only when location/address access has been granted. |
| Trusted contact | Search only where the Care Profile explicitly grants location or emergency access. |
| Care Partner | Not included in this feature’s initial scope; assigned-visit navigation is a separate workflow. |
| Operations user | May view an SOS-linked hospital search in audit context, subject to role-based access. |

## 5. User journeys

### 5.1 Mobile: elder requests nearby hospitals

1. The user selects **Get Help** → **Nearby hospitals**, or asks the voice agent, “Find a hospital near me.”
2. Goldenly states: “I’ll use your location to show nearby hospitals. You can choose whether to share it.”
3. The user allows location, chooses a saved home address, or enters/selects another address.
4. Goldenly shows up to five nearby hospital cards.
5. The user selects **Call** or **Directions** on a chosen card.
6. Goldenly opens the native phone dialer or mapping application; it does not make a silent call.

### 5.2 Web: coordinator searches for a member

1. Sid switches to Lisa’s Care Profile.
2. He selects **Get Help** → **Nearby hospitals**.
3. Goldenly displays “Searching near Lisa’s saved address” or asks Lisa/Sid to select an authorised location.
4. Sid sees hospital cards and can use **Call** or **Directions**.
5. The audit event identifies Sid as the actor and Lisa as the Care Profile, without granting Sid broader data access.

### 5.3 Voice-agent entry point

1. User says: “What hospitals are nearby?”
2. The voice agent identifies the request as `hospital_information`, confirms the target care profile if more than one is available, and asks for location permission/source if needed.
3. The agent invokes the hospital-search backend tool.
4. The app renders factual hospital cards and says, “Here are nearby hospitals. Would you like me to open directions or call one?”
5. The user must explicitly choose a hospital and confirm the action.

### 5.4 SOS entry point

If a user explicitly triggers SOS or asks for immediate emergency help, Goldenly must first present country-aware emergency actions and trusted-contact notification. Nearby hospitals are a secondary action, not the primary response.

## 6. Location model and consent

### 6.1 Permitted location sources

| Source | Use case | Consent requirement |
| --- | --- | --- |
| Device current location | Elder using mobile or coordinator using their own device for themselves | Runtime permission; one-time or ongoing preference |
| Care Profile saved address | Family coordinator searches for an elder at home | Care-profile address/location sharing permission |
| Manually selected address | User needs a hospital near a different authorised location | Explicit selection for that search |
| SOS location | Emergency workflow | Separate SOS/location consent and full audit record |

### 6.2 Location rules

- The feature shall request the least precise location that gives useful results.
- Users may decline location permission and search using a city, postal code, or manually selected address.
- Location must not be collected in the background solely for hospital recommendations.
- The active Care Profile must be named before a coordinator searches using a saved profile address.
- Search location must not be exposed to another Circle member without the profile owner’s applicable permission.
- Exact coordinates are transmitted to Google Places only for the active user-requested search and should not be stored beyond what is necessary for security/audit and permitted retention.

## 7. Google Places integration

### 7.1 API choice

Goldenly shall use **Places API (New) Nearby Search** for location-based hospital discovery. The backend sends the search request; Google API keys must never be embedded in the web client or Expo app.

The initial search filter uses the supported `hospital` place type. Goldenly may inspect returned place types to improve labelling, but must not infer clinical capabilities or emergency capacity from a place type alone.

### 7.2 Request behaviour

| Parameter | MVP requirement |
| --- | --- |
| Search centre | Consented latitude/longitude from the selected location source |
| Search radius | Default 5 km in dense areas; configurable fallback expansion up to 20 km when results are insufficient |
| Included type | `hospital` |
| Result count | Maximum 5 visible cards; request no more than 10 results server-side for filtering/deduplication |
| Ranking | Distance where available; do not label results “best” |
| Language | Care Profile or Account User preferred language when supported |
| Field mask | Request only display name, place ID, location, formatted address, phone, Maps URI, current opening hours, business status, and place types as needed |

Google requires a field mask for Nearby Search and bills by requested fields. Goldenly must keep the field mask minimal, monitor usage, and review Google Maps Platform attribution, caching, and display requirements before production launch. [Nearby Search (New)](https://developers.google.com/maps/documentation/places/web-service/nearby-search)

### 7.3 Server-side components

```text
Web / Mobile UI
  -> HospitalSearchController
  -> HospitalSearchPolicy (active profile + permission + consent checks)
  -> LocationResolver
  -> GooglePlacesClient
  -> HospitalResultNormalizer
  -> AuditEvent writer
  -> Hospital cards returned to UI
```

### 7.4 Result normalisation

The backend returns a Goldenly-safe response. It must not proxy arbitrary Google data or expose the Google API key.

```json
{
  "search_context": {
    "care_profile_name": "Lisa Sharma",
    "location_source": "saved_address",
    "location_label": "Near Lisa’s home"
  },
  "hospitals": [
    {
      "place_id": "google-place-id",
      "name": "Example General Hospital",
      "address": "Short formatted address",
      "distance_meters": 1800,
      "phone_number": "+91 ...",
      "open_status": "Open now",
      "maps_url": "Google Maps URI",
      "call_available": true,
      "directions_available": true,
      "disclaimer": "Confirm services and availability directly with the hospital."
    }
  ]
}
```

Distance may be calculated as approximate straight-line distance using the selected search point and returned place coordinates. The UI must label it “approx.” and must not present it as travel time.

## 8. Web experience

### 8.1 Entry points

- Dashboard quick action: **Find nearby hospitals**.
- Get Help page: **Hospitals near [active profile]**.
- Care Timeline/SOS event detail: **Nearby hospitals** secondary action.
- Voice agent result: **View nearby hospitals**.

### 8.2 Required UI elements

- Active-profile banner: “Viewing hospitals near Lisa Sharma.”
- Location source with **Change** control.
- Search loading state that explains that Goldenly is looking up nearby hospitals.
- Five or fewer result cards initially.
- Each card includes hospital name, approximate distance, address, current open/closed/unknown status, and clear disclaimer.
- **Call** and **Directions** buttons as separate, equal-priority controls.
- Optional **View in Google Maps** link.
- “Not an emergency service” note and visible **SOS / Call emergency services** action.

### 8.3 Web action behaviour

- **Call:** use a `tel:` link where the browser/device supports it; otherwise show the number in a copy-friendly dialog.
- **Directions:** open the returned Google Maps URI in a new tab.
- Goldenly logs the action intent but does not record whether the external call completed.

## 9. Mobile experience

### 9.1 Entry points

- Get Help → **Nearby hospitals**.
- Persistent SOS flow → **Find nearby hospitals**.
- Voice-agent response card.
- My Care → saved preferred hospital, if the member chooses one in a future enhancement.

### 9.2 Accessibility requirements

- Minimum 48×48 dp touch target for Call, Directions, location selection, and SOS controls.
- Large-text support without clipping critical hospital name, address, or action buttons.
- Screen-reader labels such as “Call Example General Hospital” and “Open directions to Example General Hospital.”
- High-contrast mode and colour-independent open/closed indicators.
- The voice agent must be able to read a concise list and ask, “Would you like hospital one, two, or three?”
- Do not require map gestures to use the feature.

### 9.3 Mobile action behaviour

- **Call:** invoke the operating system dialer with the selected hospital phone number. The user makes the final call action.
- **Directions:** open the selected Maps URI in the device’s preferred supported map application/browser.
- If a phone number is unavailable, disable Call with accessible text: “Phone number unavailable; use Directions or view in Maps.”

## 10. Safety, medical, and emergency policy

- Goldenly shall never state that a displayed hospital is the best hospital, the correct facility for a symptom, or currently able to accept the person.
- Goldenly shall never diagnose symptoms or decide whether an ambulance is medically necessary.
- For explicit emergency requests, show the emergency action before hospital search. In India, Goldenly can present 112; in the United States, it can present 911. [India ERSS](https://112.gov.in/), [US National 911 Program](https://www.911.gov/calling-911/)
- Goldenly shall not automatically dial 112/911, call a hospital, notify a hospital, or share location merely because a voice model detected concerning language.
- Trusted-contact notification and SOS location sharing must follow separate consent rules and require an explicit SOS action/confirmation.
- Each hospital list must include a concise disclaimer: “Goldenly shows nearby hospital listings. Confirm services and availability directly with the hospital.”

## 11. Voice-agent and AI policy

The voice agent may understand multilingual natural-language requests and convert them into structured, non-clinical intents:

```text
find_hospitals
change_search_location
open_directions
call_hospital
start_sos
notify_trusted_contacts
```

The agent must:

- Confirm the active Care Profile when ambiguity exists.
- Request/confirm the location source before a search.
- Use only the `find_hospitals` tool for hospital discovery.
- Present returned factual results without adding medical claims.
- Require a clear confirmation before `call_hospital`, `start_sos`, or `notify_trusted_contacts`.
- Never invoke an emergency action based only on inferred urgency.

GPT-5.6 should be used through the Responses API for multi-turn tool workflows. Its role is intent/language understanding and safe orchestration; deterministic policy checks and product UI enforce consent and action gates. [GPT-5.6 guidance](https://developers.openai.com/api/docs/guides/model-guidance?model=gpt-5.6)

## 12. Privacy, security, and compliance

- Google Places API key is stored server-side in secrets management and restricted by API, application, IP/service identity, and billing controls as appropriate.
- Never log raw Google API keys, precise location, or hospital-search query content in client analytics.
- Audit records contain actor, care profile, consent basis, coarse location source, time, and action; avoid storing exact coordinates unless essential for an SOS event.
- Follow Google Maps Platform terms for attribution, result display, cache/storage, and use of Places content.
- Role-based access and the existing Care Profile permission model apply to saved-address searches.
- Location, call, and directions actions must be included in member-access history where required by the care profile’s sharing policy.

## 13. Failure and edge-case behaviour

| Condition | Required experience |
| --- | --- |
| Location permission denied | Offer saved address, city/postal-code search, or manually selected address. |
| No saved address / no permitted profile access | Explain why the location cannot be used and ask the user to select an authorised location. |
| No nearby results | Offer expanded radius, address change, or open a broader Google Maps search. |
| Places API unavailable/rate limited | Show a factual error and a prominent emergency-services action; do not fabricate results. |
| Hospital has no phone | Hide/disable Call and keep Directions. |
| Hospital is marked permanently closed | Exclude it from normal results. |
| Open status unavailable | Display “Hours unavailable”; do not infer it is open. |
| User is offline | Show saved preferred hospital/contact if locally available and emergency call action; otherwise explain that nearby search needs connectivity. |
| Voice request is ambiguous | Ask a short clarification: “Do you want nearby hospitals or immediate emergency help?” |
| User triggers SOS | Prioritise SOS screen and emergency contact actions; hospital search remains optional. |

## 14. Data model additions

```text
HospitalSearchEvent
  actor_account_user
  care_profile
  location_source (current_location, saved_address, manual_location, sos)
  consent_basis
  country
  searched_at
  result_count
  status

HospitalPlaceAction
  hospital_search_event
  google_place_id
  action_type (call, directions, maps_view)
  initiated_at

CareProfileLocationPreference
  care_profile
  saved_address_reference
  location_sharing_preference
  preferred_hospital_place_id (future)
```

Google-derived place details must be handled according to Google Maps Platform terms. Goldenly should retain user action/audit events independently from any restricted place-content caching policy.

## 15. API requirements

### 15.1 Goldenly API

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `/api/v1/care_profiles/:id/nearby_hospitals` | POST | Search hospitals using authorised, consented location input. |
| `/api/v1/hospital_searches/:id/actions` | POST | Record Call/Directions/Maps action intent. |
| `/api/v1/care_profiles/:id/location_preference` | GET/PATCH | Read/update saved-address and location-sharing preferences. |

### 15.2 Search request contract

```json
{
  "location_source": "saved_address",
  "location": {
    "latitude": 12.9716,
    "longitude": 77.5946
  },
  "radius_meters": 5000,
  "language_code": "en"
}
```

The backend must ignore supplied coordinates when the caller lacks permission for the target Care Profile, validate coordinate/radius limits, and never accept an arbitrary Google field mask from the client.

## 16. Functional requirements

| ID | Requirement |
| --- | --- |
| HOS-01 | The system shall let an authorised user search nearby hospitals from web and mobile. |
| HOS-02 | The system shall require or reuse applicable location consent before using device or saved profile location. |
| HOS-03 | The system shall clearly identify the active Care Profile for coordinator searches. |
| HOS-04 | The system shall use Google Places Nearby Search through a server-side integration. |
| HOS-05 | The system shall show no more than five initial hospital results with factual name, address, approximate distance, phone where available, and maps link. |
| HOS-06 | The system shall provide a user-initiated Call action and must not place an automatic call. |
| HOS-07 | The system shall provide a Directions action that opens the selected place in a maps application/browser. |
| HOS-08 | The system shall provide accessible error, no-results, and location-denied alternatives. |
| HOS-09 | The system shall not represent hospital listings as clinical recommendations or emergency-capacity information. |
| HOS-10 | The voice agent shall require confirmation before calling a hospital, triggering SOS, or notifying trusted contacts. |
| HOS-11 | The system shall record hospital search and external-action intent in the audit trail. |
| HOS-12 | The system shall keep Google API credentials server-side and request a minimal approved field mask. |

## 17. Acceptance criteria

1. A member can allow current location on mobile and receive up to five nearby hospital cards.
2. A coordinator can search near an elder’s saved address only when the elder has granted the required location/address access.
3. A user who denies location can search by an entered address, city, or postal code.
4. Each hospital card provides a Call button only when an API-supplied phone number exists.
5. Selecting Call opens the device/browser dialer with the selected number and does not silently place the call.
6. Selecting Directions opens the selected hospital’s Maps URI.
7. A result marked permanently closed is not displayed as an ordinary hospital option.
8. The UI indicates that distance is approximate and does not claim travel time or clinical suitability.
9. A voice request for nearby hospitals results in a structured hospital search only after target/profile and location ambiguity are resolved.
10. An explicit SOS request prioritises emergency actions; it does not silently invoke hospital search or emergency calling.
11. The Google Places key never appears in mobile bundles, browser JavaScript, or API responses.
12. Hospital search, Call, and Directions action intent are visible in the audit record with the correct actor and Care Profile.

## 18. Delivery sequence

1. Care Profile location preference and permission checks.
2. Server-side Google Places client, field mask, result normaliser, and audit events.
3. Member web hospital finder with Call/Directions actions.
4. Expo mobile hospital finder with runtime location permission and native actions.
5. Voice-agent `find_hospitals` tool and confirmation policy.
6. SOS handoff, no-results/offline flows, accessibility testing, usage monitoring, and terms/compliance review.

## 19. Decisions to confirm before implementation

1. Should the member be able to save a preferred hospital and an alternate hospital in MVP?
2. Should the initial mobile implementation use device current location only, saved care address only, or both?
3. Is 5 km with a fallback to 20 km acceptable for both India and the United States, or should each country/city have configurable defaults?
4. Which notification channel is approved for a future SOS trusted-contact alert: push, SMS, WhatsApp, or a combination?
5. Should a hospital search be available to a trusted contact with emergency-only permission, or only during an active SOS event?


## 20. Confirmed MVP decisions

The following decisions supersede the open questions in Section 19.

| Area | Confirmed decision |
| --- | --- |
| Preferred hospital | A Care Profile may save one preferred hospital. Store its Google Place ID and display it with the label “Preferred hospital”; do not present it as a Goldenly medical recommendation. |
| Default search location | Use current device location when access is enabled. If it is off, denied, or unavailable, search near the authorised saved Care Profile address by default. |
| Default radius | 10 km. If there are no useful results, Goldenly must explain and obtain user acknowledgement before broadening the search radius. |
| SOS contact alerts | Send both push notification and SMS to configured, consented trusted contacts. |
| Coordinator/trusted-contact access | The hospital finder is available to authorised trusted contacts and coordinators, subject to the Care Profile’s location/address permission. |

### 20.1 Preferred-hospital requirements

- An authorised Care Profile owner or coordinator with the applicable manage permission may mark one result as the Care Profile’s preferred hospital.
- Store the Google Place ID and the member’s selection time. Re-fetch current hospital details when displaying it; do not rely on cached address, phone, or opening status as authoritative.
- Show the preferred hospital first when it is within the search context, with a clear preference label and a Change preferred hospital control for authorised users.

### 20.2 Location and alert requirements

- Current location is the primary source only when granted at runtime. The saved Care Profile address is the privacy-preserving default fallback.
- For an active SOS event, alerts must record the actor, Care Profile, recipients, delivery channels, consent basis, delivery result, and any shared location.
- Emergency-only contacts may access the hospital finder only within the permission scope configured by the Care Profile owner; ordinary trusted contacts require explicit location/address access.

Remaining implementation choices: select the SMS delivery provider, determine country-specific sender identities and templates, decide whether to add an alternate preferred hospital later, and set the broadened-search radius after 10 km yields no useful results.
