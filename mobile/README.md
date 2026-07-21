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

The Rails service requires the Twilio environment variables listed in the root
`.env.example`. Configure the Twilio Verify email channel with a verified
SendGrid sender and template in Twilio before testing email OTPs.

Emergency and location-sharing actions are simulated confirmation flows. A production app must integrate local emergency services, explicit consent records, and a secure dispatch backend before sending any notifications.
