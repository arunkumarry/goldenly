# Goldenly Mobile

Accessible Expo companion for members. It implements the BRD’s simplified daily plan, care access, trusted-circle overview, help-request confirmations, AI safety messaging, and consent-aware SOS flow.

```sh
npm install
npm start
```

## OTP authentication

Both the web and native app use one-time verification codes. The native app uses
the Rails `/api/v1/auth/*` endpoints and stores its access and refresh tokens in
the device keychain/keystore via Expo SecureStore.

Copy `.env.example` to `.env` and set `EXPO_PUBLIC_API_URL` to the HTTPS URL of
the Rails API. For a physical device, do not use `localhost`.

Phone-number verification requires the Twilio environment variables listed in
the root `.env.example`. Email verification does not require Twilio locally.

For local email OTP testing, use the Mailpit inbox at `http://localhost:8026`.
Email identifiers are verified by Rails through Mailpit in development; phone
identifiers continue to use Twilio Verify.

## Voice assistant

The **Talk to Goldenly** sheet supports English and Telugu voice-to-text, then
sends the transcript to the authenticated Rails care-agent API. It asks for
microphone and speech-recognition permission only after the member taps
**Speak**. The app uses native iOS/Android speech recognition and therefore
cannot run this feature in Expo Go. After installing dependencies, create a
development build:

```sh
npx expo run:ios
# or
npx expo run:android
```

Every reminder, provider request, and emergency alert needs an explicit
confirmation. Emergency confirmation records the alert in Goldenly and exposes
a device-native call button for the member’s country emergency number; it does
not yet SMS/call trusted contacts or hospitals automatically.

Emergency location consent is recorded with the alert. A production app must add local emergency-service routing, trusted-contact notification delivery, hospital dispatch, and an auditable consent system before sending notifications.
