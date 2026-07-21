# Goldenly Mobile Identity, Care Profiles & Access BRD

## 1. Purpose

Define an unambiguous sign-up, login, care-profile, invitation, and consent model for Goldenly mobile and web. This specification supports elders who use Goldenly directly, family members who coordinate care remotely, and people who do both.

The design must protect an elder's privacy while remaining simple enough for an older person to use independently with large controls, a PIN/biometric unlock, and a multilingual voice assistant.

## 2. Product decision

Goldenly must use the following four distinct concepts. The product must not use the word “member” as a substitute for all four.

| Concept | Definition | Can sign in? | Holds care data? |
| --- | --- | ---: | ---: |
| **Account User** | A real person with credentials and an authenticated Goldenly session. | Yes | Not necessarily |
| **Care Profile** | The care, routine, health-document, service, and consent record for one individual. | No, unless claimed | Yes |
| **Circle Membership** | A relationship granting one Account User scoped access to one Care Profile. | N/A | No |
| **Profile Invitation** | A single-use invitation that lets the person represented by a Care Profile claim it and create/sign in to their own Account User. | After acceptance | No |

An Account User may be linked to their own Care Profile. Therefore, a person may be both an Account User and a care recipient.

## 3. Goals

- Let a family coordinator set up care for one or more people without requiring a web browser.
- Let an elder safely claim and use their own profile on their own phone.
- Allow a person to manage their own care and a spouse/parent’s care from one account.
- Ensure no one sees another person’s care data without explicitly granted access.
- Avoid passwords and shared credentials for elder-facing login.
- Support mobile-only onboarding, reminders, services, trusted-circle management, and SOS.

## 4. Non-goals for the MVP

- Clinical diagnosis, treatment recommendations, or autonomous health-risk predictions.
- Shared family passwords or accounts.
- Automatic sharing between spouses, parents, or siblings.
- Automatic emergency-location sharing outside a consented emergency workflow.
- Operations-admin and provider-mode authentication flows; they are separate role-based products.

## 5. Personas and roles

### 5.1 Account roles

An Account User can have more than one role at the same time.

| Role | Description |
| --- | --- |
| **Self manager** | Uses Goldenly for their own care profile. |
| **Care coordinator** | Coordinates one or more other people’s profiles, such as an adult child. |
| **Trusted contact** | Has limited access granted by a care-profile owner or authorised coordinator. |
| **Care recipient** | The individual represented by a Care Profile; may or may not have claimed it yet. |

### 5.2 Care Profile states

| State | Meaning | Who can manage it? |
| --- | --- | --- |
| `draft` | Created but core identity/contact details are incomplete. | Creator only |
| `unclaimed` | Set up for a person who has not yet activated their own account. | Creator, within initial consent scope |
| `claimed` | The individual has verified their contact method and linked an Account User. | The individual; delegates only by granted permission |
| `assisted` | The individual cannot or chooses not to use the app; an authorised coordinator manages it. | Authorised coordinator, with recorded consent/basis |
| `archived` | No longer active; retained according to data-retention policy. | Restricted administrative access |

## 6. Authentication and device access

### 6.0 Shared web and mobile identity model

Web and mobile are different interfaces over the same platform records: Account User, Care Profile, Circle Membership, Profile Invitation, Consent Record, and Audit Event. Goldenly must not create separate web and mobile accounts, credentials, profile ownership, or permission stores.

| Requirement | Web | Mobile |
| --- | --- | --- |
| Authentication | Phone OTP for the same Account User | Phone OTP for the same Account User; optional biometric/PIN unlock after sign-in |
| Active care profile | Profile switcher for accessible Care Profiles | Profile switcher when managing another person; own profile opens by default |
| Invitation/claim | Invitation link opens the browser claim flow | Invitation deep link opens the app claim flow; store fallback when the app is unavailable |
| Consent and permissions | View and manage the same permissions permitted to the signed-in user | View and manage the same permissions permitted to the signed-in user |
| Audit history | Writes to the same audit trail | Writes to the same audit trail |

After OTP verification, Goldenly shall identify the Account User, retrieve the Care Profiles to which they have access, and open their own linked Care Profile by default. If the user coordinates additional profiles, the interface shall provide a clearly labelled profile switcher.

The active profile must be visible whenever a user is viewing or acting on another person’s care. No web or mobile screen may blend data, tasks, documents, or timelines from multiple Care Profiles in the MVP.

The web experience may offer a denser layout for documents, subscriptions, multiple relatives, and detailed permission management. Mobile must still support complete onboarding and core daily coordination; web must not be required to claim a profile, manage consent, create reminders, request services, or use SOS.

### 6.1 Required sign-in method

1. Phone-number verification by one-time passcode (OTP) is the primary login method.
2. Email is optional as a recovery and invitation channel.
3. After a successful OTP login, users may enable biometric unlock (Face ID, Touch ID, fingerprint) or a simple app PIN.
4. The mobile app must never display, generate, or send a reusable password as “login details.”
5. OTP expiry, retry limits, device/session revocation, and audit logs are required.

### 6.2 Invitation delivery

An invitation can be delivered by SMS, WhatsApp, or email. It contains a single-use, expiring deep link. Opening the link must lead to a short, accessible “Claim your Goldenly profile” flow.

If the invitee already has a Goldenly account with the same verified phone number, the invite links the Care Profile after confirmation; it must not create a duplicate account.

### 6.3 Elder-friendly claim flow

1. Open the invite link.
2. Confirm first name and phone number with OTP.
3. Choose language and accessibility preferences: text size, high contrast, voice guidance, and biometric/PIN option.
4. Review who currently has access and what each person can see/do.
5. Confirm, adjust, or decline those permissions.
6. Land on the elder’s own **Today** screen.

The flow must be achievable without typing a password, reading dense legal copy, or using a desktop browser.

## 7. Consent and access model

### 7.1 Core rule

Access is granted **per Account User, per Care Profile, per permission**. There is no global family-access permission.

The Care Profile owner controls access after the profile is claimed. Before claim, the creator has only the access needed to coordinate the requested setup and must be shown as a temporary coordinator.

### 7.2 Permission catalogue

| Permission | View | Manage | Emergency-only |
| --- | ---: | ---: | ---: |
| Appointments and routines | Yes | Yes | No |
| Service requests and visit status | Yes | Yes | No |
| Medication updates | Yes | Yes | No |
| Health and medical documents | Yes | Upload/manage | No |
| Wellbeing updates | Yes | No | No |
| Trusted circle | No | Invite/change access | No |
| Emergency alerts | Yes | Configure contacts | Yes |
| Location during an active consented SOS event | No | No | Yes |

`Manage` includes the corresponding `View` permission. A user must not receive a permission that is broader than the one explicitly chosen.

### 7.3 Delegation rules

- A Care Profile owner can invite others and change permissions for their own profile.
- A coordinator can invite another person only if they hold `Manage trusted circle` for that profile.
- A viewer cannot share, export, invite, or change permissions.
- A coordinator cannot grant themselves or another person permissions that exceed their own granted scope.
- Every invitation, permission change, consent confirmation, document view, and emergency access must be audit logged.
- Emergency-only access must be time-limited to an active SOS event and visible in the access history.

## 8. Required mobile onboarding journeys

### 8.1 Journey A: “Set up Goldenly for myself”

1. User enters and verifies phone number.
2. User selects **I am setting up care for myself**.
3. Goldenly creates one Account User and one linked Care Profile.
4. User completes care basics, emergency contacts, language, accessibility, and consent preferences.
5. User lands in Elder Mode.

### 8.2 Journey B: “Set up Goldenly for someone else”

1. Coordinator enters and verifies their own phone number.
2. Coordinator selects **I am setting up care for someone else**.
3. Coordinator creates a Care Profile for the individual and records the relationship, contact method, and initial consent/basis.
4. Coordinator selects their own access level.
5. Coordinator may send a profile-claim invitation immediately or later.
6. Coordinator lands in Family/Coordinator Mode for that Care Profile.

### 8.3 Journey C: “Set up care for myself and my spouse/parent”

1. User completes Journey A for themselves.
2. From **My Circle** or **Add a person**, user creates another Care Profile.
3. The new profile is initially `unclaimed`; the creator is an authorised coordinator.
4. The creator invites the person to claim the profile, if they can and want to use Goldenly.
5. Once claimed, the care recipient confirms or changes the creator’s access.

## 9. Scenario requirements

### 9.1 Scenario 1: Sid, Lisa, and Sal live in different countries

**Given** Sid has an Account User

**When** Sid creates Care Profiles for Lisa and Sal

**Then** Goldenly must create two separate profiles and two separate Circle Memberships for Sid.

**When** Sid sends invitations to Lisa and Sal

**Then** each invitee receives a single-use claim link and creates/logs into their own Account User through OTP.

**When** Lisa claims her profile

**Then** she sees only Lisa’s elder-mode home screen by default and reviews Sid’s access.

**And** Lisa must not automatically see Sal’s data.

**And** Sid sees only the data/categories Lisa and Sal independently allow for their profiles.

### 9.2 Scenario 2: Sal manages his own and Lisa’s care

**Given** Sal signs up for himself

**When** he selects the self-setup journey

**Then** Sal is both an Account User and the owner of Sal’s linked Care Profile.

**When** Sal adds Lisa

**Then** Goldenly creates Lisa’s Care Profile and gives Sal a Circle Membership with selected coordinator permissions.

**When** Sal opens the app

**Then** he can use a clearly labelled profile switcher to choose **My care** or **Lisa’s care**.

**And** the app must visibly state which person’s information is currently being viewed.

**When** Lisa claims her profile

**Then** she has Elder Mode on her own phone and may keep, reduce, or revoke Sal’s access.

### 9.3 Scenario 3: both spouses want reciprocal access

Lisa and Sal must each explicitly grant the other access to their own Care Profile. Goldenly may offer a suggested reciprocal setup during onboarding, but it must require two separate confirmations.

### 9.4 Scenario 4: care recipient does not use a smartphone

The profile remains `assisted` or `unclaimed`. The authorised coordinator can manage permitted tasks. The system must record the consent/basis, show an invitation option for later, and never imply that the care recipient has personally reviewed permissions.

### 9.5 Scenario 5: invitee changes phone number or loses an invitation

The coordinator can resend or cancel a pending invite. The invitee may use an approved recovery/support process. Cancelling an invitation invalidates its deep link immediately.

## 10. Mobile information architecture

### 10.1 Elder Mode

Elder Mode must be the default when the signed-in user is viewing their own linked Care Profile.

- **Today:** medicines, appointments, visits, reminders, and a large Talk to Goldenly entry point.
- **Talk to Goldenly:** voice/text requests in the selected language; confirmation before any action.
- **Get Help:** medical support, household help, shopping, transport, companionship, and digital assistance.
- **My Care:** medicines, appointments, documents, previous services, and care timeline.
- **My Circle:** trusted contacts and permissions relevant to the elder.
- **SOS:** persistent emergency workflow with clear consented contacts.

### 10.2 Family/Coordinator Mode

Family/Coordinator Mode is shown when the user switches to a profile they manage but do not own.

- Persistent profile switcher with name, photo/initial, and relationship.
- Profile-specific schedule, requests, visits, documents, and alerts within granted scope.
- Clear label such as **Viewing Lisa’s care** on every relevant screen.
- Circle and sharing management only when the user has that permission.
- No blended or combined timeline across multiple people in the MVP.

## 11. AI and voice requirements

- Voice is an input method, not an authentication method in MVP.
- The assistant must honour the current selected Care Profile and must confirm the target person before creating a reminder, booking a service, sending a notification, or sharing data.
- The assistant may understand and reply in the user’s preferred language.
- The assistant may prepare reminders, service requests, and summaries; it must require confirmation before committing an action.
- The assistant must not diagnose, prescribe, recommend treatment, or make clinical decisions.
- If it detects an urgent request, it must present the SOS/emergency path and safety guidance, not a diagnosis.

## 12. Data model requirements

At minimum, implement these records and relationships:

```text
AccountUser
  has_many CareProfileLinks
  has_many CareProfiles through CareProfileLinks

CareProfile
  belongs_to AccountUser as optional owner (set after claim)
  has_many CareProfileLinks
  has_many ProfileInvitations
  has_many ConsentRecords
  has_many AuditEvents

CareProfileLink
  belongs_to AccountUser
  belongs_to CareProfile
  relationship_to_person
  permissions (structured data)
  status

ProfileInvitation
  belongs_to CareProfile
  invited_contact
  delivery_channel
  token_digest
  expires_at
  accepted_at / cancelled_at

ConsentRecord
  belongs_to CareProfile
  subject, purpose, permissions, captured_at, source

AuditEvent
  actor, care_profile, action, metadata, occurred_at
```

Medical and care data must always belong to a Care Profile, never directly to an Account User. This is essential for supporting an Account User who manages several people.

## 13. Functional requirements

| ID | Requirement |
| --- | --- |
| IAM-01 | The system shall support OTP-based account creation and sign-in using a verified phone number. |
| IAM-02 | The system shall allow one Account User to create and manage multiple Care Profiles. |
| IAM-03 | The system shall allow an Account User to be linked to and own their own Care Profile. |
| IAM-04 | The system shall allow a Care Profile to remain unclaimed or assisted. |
| IAM-05 | The system shall send expiring, single-use profile-claim invitations through supported channels. |
| IAM-06 | The system shall require an invitee to verify identity/contact information before claiming a profile. |
| IAM-07 | The system shall show existing access and request confirmation when a Care Profile is claimed. |
| IAM-08 | The system shall enforce permissions by Care Profile and data category. |
| IAM-09 | The system shall provide a prominent profile switcher to users who can access multiple Care Profiles. |
| IAM-10 | The system shall show the active Care Profile’s name on coordinator-mode screens. |
| IAM-11 | The system shall allow profile owners and authorised delegates to invite trusted contacts. |
| IAM-12 | The system shall record immutable audit events for authentication, invitations, consent, permission, data-access, and SOS actions. |
| IAM-13 | The system shall work end-to-end from mobile; web must not be required for onboarding or daily care coordination. |
| IAM-14 | The system shall support accessibility preferences and preferred language per Care Profile. |
| IAM-15 | The system shall require confirmation before AI-triggered notifications, sharing, reminders, or service bookings. |

## 14. Acceptance criteria

1. Sid can sign up on mobile, create Lisa and Sal profiles, and send two independent invitations.
2. Lisa can claim her profile with OTP and access only her own elder-mode dashboard.
3. Sid cannot view Lisa’s documents when Lisa has not granted document permission.
4. Lisa does not see Sal’s information unless Sal explicitly shares it with her.
5. Sal can create an account, create his own linked Care Profile, add Lisa, and switch between his and Lisa’s profile without mixing their data.
6. Lisa can claim her profile and reduce Sal’s access without deleting her own data.
7. An unclaimed profile can be managed by its recorded temporary coordinator but displays an invitation/claim status.
8. A user with View-only access cannot invite another person, change access, export documents, or create a service request.
9. The app can be fully onboarded and used without a web browser.
10. The voice assistant asks for confirmation and identifies the target care profile before it creates a reminder or request.

## 15. MVP implementation sequence

1. Account User, Care Profile, profile link, OTP authentication, and active-profile switching.
2. Create-self and create-someone-else mobile onboarding.
3. Invitation, claim, consent-review, and resend/cancel flows.
4. Permission enforcement and audit events.
5. Elder Mode and Coordinator Mode navigation.
6. Voice/text assistant with confirmation-only action proposals.
7. SOS, accessibility settings, recovery/support, and compliance hardening.
