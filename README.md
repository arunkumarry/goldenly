# Goldenly MVP

Goldenly is an AI-assisted care-coordination MVP for members: a Rails 8 Hotwire dashboard, versioned JSON API, PostgreSQL persistence layer, and an Expo companion.

## Included

- Family/care dashboard: daily schedule, wellbeing, services, timeline, and trusted circle.
- Member mobile companion: large daily tasks, help categories, voice-entry affordance, and persistent SOS action.
- API endpoints: `GET /api/v1/dashboard`, reminders, and service-request creation.
- Consent-safe AI boundary: the assistant can interpret multilingual requests but cannot dispatch, notify, share data, or give clinical advice without a separate confirmation flow.
- Central theme tokens in `app/assets/stylesheets/application.css` (the five requested colors are the top-level variables).

## Run the web app

The easiest local setup uses Docker and does not require PostgreSQL on your
machine:

```sh
docker compose up --build
```

Open `http://localhost:3000`. The `web` container waits for PostgreSQL, creates
or migrates the database, and loads the safe demo seed data on startup. Stop
the stack with `docker compose down`; add `--volumes` to also remove local
database data.

Set the Twilio Verify environment variables from `.env.example` before using
OTP sign-in or signup. Twilio Verify handles SMS and email verification; do not
put Twilio credentials in source control.

To run Rails directly instead, start PostgreSQL locally, create a role that can
create the `goldenly_development` database, then run:

```sh
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

## Configure AI

Set `OPENAI_API_KEY` and `OPENAI_MODEL` in the Rails runtime environment. The assistant uses the Responses API only when both are present; otherwise it provides the safe local fallback, so onboarding and UI work without secrets. Keep the API key server-side only.

## Run mobile

```sh
cd mobile
npm install
npm start
```

The Expo app is intentionally local-first for this MVP. Add an authenticated API client after the Rails deployment URL is available.

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
