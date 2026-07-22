# Goldenly

[Goldenly](https://goldenly-web-949146314151.asia-south1.run.app/) is a global, AI-assisted care-coordination platform for members, their families, and their trusted circles. It brings reminders, service requests, care information, profile access, and a voice-first mobile companion into one connected experience.

**Live app:** [https://goldenly-web-949146314151.asia-south1.run.app/](https://goldenly-web-949146314151.asia-south1.run.app/)

## What Goldenly does

- Creates member care profiles for oneself or someone else, including global address, country, region, city, coordinates, and preferred language.
- Supports passwordless email or phone-number sign-up and sign-in with one-time verification codes.
- Lets a coordinator switch between multiple member profiles without losing context.
- Organizes reminders, recurring schedules, a calendar, appointments, medicines, documents, and care activity.
- Supports service requests for medical health checkups, diagnostic services, household help, shopping, transport, companion visits, and digital assistance.
- Lets families invite a trusted circle by email or phone number and manage profile-specific permissions.
- Provides a responsive Rails web dashboard and an Expo mobile app for iOS and Android.
- Uses Google Places for structured address capture and future-ready location/navigation support.

## Goldenly AI voice agent

Goldenly AI is currently mobile-first. Members can talk or type to ask about recorded care information, including reminders, medication schedules, appointments, and service requests.

- English and Telugu voice interactions are supported for the hackathon experience.
- The agent uses the active member profile as context.
- It can ask follow-up questions to collect a requested service date, hour, and details before creating a service request.
- Care actions require confirmation before a record is created or an emergency workflow is triggered.
- The agent provides only basic wellbeing guidance; it does not diagnose, prescribe, or replace medical professionals.

## Built with

- Ruby on Rails 8, PostgreSQL, Hotwire, Turbo, and Stimulus
- Expo and React Native for the iOS and Android mobile apps
- RubyLLM and OpenAI for member-aware conversations and action planning
- GPT-5.6 Luna for the Goldenly AI voice agent
- Device speech recognition and text-to-speech for voice interactions
- Twilio Verify for OTP authentication
- Brevo SMTP for production email delivery
- Google Maps Places API for global address search and location data
- Docker, Artifact Registry, Cloud SQL, Secret Manager, and Google Cloud Run

Goldenly was built with **Codex** and **GPT-5.6 Terra**.

## Architecture

```text
Web dashboard (Rails + Hotwire) ─┐
                                 ├── Rails API + service objects ── PostgreSQL / Cloud SQL
Mobile app (Expo + React Native) ┘              │
                                                ├── RubyLLM + GPT-5.6 Luna
                                                ├── Twilio Verify
                                                ├── Brevo SMTP
                                                └── Google Places API
```

The Rails application uses service objects for integrations and workflow logic, model concerns for shared domain behaviour, and Turbo Frames/Streams with Stimulus for responsive server-rendered UI.

## Local development

### Prerequisites

- Docker Desktop (recommended for the web app)
- Node.js and npm for the mobile app
- Xcode for iOS development and/or Android Studio for Android development

### Web app

```sh
docker compose up --build
```

Open [http://localhost:3000](http://localhost:3000). Mailpit is available locally at [http://localhost:8026](http://localhost:8026) for development email testing.

Copy `.env.example` to `.env` and supply only the integrations you want to test. Never commit `.env` files or provider credentials.

### Database setup

For the Docker development environment:

```sh
docker compose exec web bin/rails db:prepare
```

For a clean local reset:

```sh
docker compose exec web bin/rails db:drop db:create db:migrate
```

### Mobile app

```sh
cd mobile
npm install
```

Set `EXPO_PUBLIC_API_URL` in `mobile/.env` to the API base URL, then run:

```sh
npx expo start
```

For a native iOS development build:

```sh
npx expo prebuild
cd ios && pod install && cd ..
npx expo run:ios --device
```

For Android:

```sh
npx expo run:android
```

## Production deployment

Goldenly is containerized for Google Cloud Run. The web service runs behind Thruster, which listens on Cloud Run's public port and proxies to Puma on its internal port.

- **Cloud Run service:** serves the Rails web app and API.
- **Cloud Run migration job:** runs database preparation once per deployment; web instances do not run migrations at startup.
- **Cloud SQL:** stores the primary and Solid Queue databases.
- **Secret Manager:** stores Rails, database, SMTP, Twilio, OpenAI, and Google Maps credentials.
- **Artifact Registry:** stores production container images.

Set production secrets in Secret Manager and bind them to both the web service and migration job as required. Do not use Mailpit in production; configure a real SMTP provider such as Brevo instead.

## Safety and privacy

Goldenly is designed to coordinate care, not provide clinical diagnosis. Emergency actions and data sharing require user confirmation, and trusted-circle access is scoped to an individual member profile.

## What's next

- Care-provider onboarding, matching, availability, and request fulfillment
- Production push notifications through APNs/Firebase configuration
- Emergency contact dispatch, nearby hospital routing, and provider escalation
- More languages, richer voice conversations, and wearable/health-device integrations with consent
