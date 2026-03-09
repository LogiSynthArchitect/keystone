# DOCUMENT 05 — USER PERSONAS
### Project: Keystone
**Required Inputs:** Document 02 — Market Research, Document 04 — Core Scope Definition
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## Persona 1 — Jeremie

**Role:** Founding Technician — Primary User
**Archetype:** Skilled Independent Tradesperson

| Field | Detail |
|---|---|
| Age Range | 20-35 |
| Occupation | Independent Locksmith Technician |
| Technical Proficiency | Medium-High — comfortable with Android, WhatsApp, Facebook, Instagram |
| Primary Device | Android smartphone (Tecno or Samsung) |
| Location | Greater Accra, Ghana |
| Work Context | Self-employed, works per job, no fixed office, moves between customer locations daily |

**Goals**
- Get more customers and more repeat business
- Be seen as a professional technician not just someone who fixes locks
- Build a reputation that grows without him having to explain himself every time
- Have a record of everything he has done so nothing is lost

**Frustrations — Product Relevant**
- He does good work but customers do not come back because nobody follows up with them
- When a new customer asks what he does he explains verbally every time
- He has solved difficult car programming jobs before but cannot remember exactly what
  he did when the same problem appears again months later
- His customer list is just a phone contacts list with no context

**Frustrations — Out of Scope**
- Wants more visibility on social media — not solved in V1
- Wants to hire an assistant eventually — team management is V2
- Wants to accept Mobile Money payments through an app — payments are V2/V3

**Typical Behavior**
- Wakes up and checks WhatsApp first — it is his primary communication channel
- Gets jobs through word of mouth and occasional Facebook posts
- Saves customer numbers in phone contacts with no notes attached
- Sends job photos to customers on WhatsApp after completing work
- Posts completed jobs on Facebook or Instagram occasionally
- Does not follow up with customers after a job unless they call him first

**Motivation to Switch to Keystone**
- Seeing that a professional WhatsApp follow-up message makes customers come back
- Having a shareable profile link to send to new customers instead of explaining verbally
- Knowing his customer history is organized and searchable on his phone

**Risk of Churn**
- If logging a job takes more than 60 seconds he will stop doing it
- If the app feels complicated or requires setup he will abandon it immediately
- If he does not see a real customer return within the first 30 days he will lose faith
- If the app requires internet in a low-connectivity area he will stop

**First Feature That Will Hook Him**
The WhatsApp follow-up and profile features. His biggest frustration is not getting
enough new customers. These two features directly address that frustration visibly
and immediately. The knowledge base becomes equally valuable as jobs accumulate.

---

## Persona 2 — Jean

**Role:** Founding Technician — Primary User
**Archetype:** Skilled Independent Tradesperson

| Field | Detail |
|---|---|
| Age Range | 20-35 |
| Occupation | Independent Locksmith Technician |
| Technical Proficiency | Medium-High — comfortable with Android, WhatsApp, Facebook, Instagram |
| Primary Device | Android smartphone (Tecno or Samsung) |
| Location | Greater Accra, Ghana |
| Work Context | Self-employed, works per job, no fixed office, moves between customer locations daily |

**Goals**
- Attract more customers consistently not just through occasional word of mouth
- Look professional when dealing with new customers — be taken seriously
- Keep track of the technical knowledge he builds up from difficult jobs
- Have something to show for the work he does every day

**Frustrations — Product Relevant**
- He does the same difficult jobs repeatedly but starts from scratch each time
- New customers have no way to verify he is a real professional before hiring him
- His Facebook posts get some attention but do not consistently bring new customers
- After a job is done the customer relationship ends — no system to maintain it

**Frustrations — Out of Scope**
- Wants to collaborate with Jeremie on shared jobs — team features are V2
- Wants to track his monthly income — earnings reports are V2
- Wants automated reminders sent to customers — scheduled follow-ups are V2

**Typical Behavior**
- Uses WhatsApp constantly throughout the day for both personal and work communication
- Posts job photos on Instagram and Facebook to build his reputation informally
- Saves customer numbers in phone contacts but rarely looks them up after a job
- Relies on returning customers calling him — no proactive outreach system
- Discusses difficult jobs with Jeremie verbally — no shared knowledge system exists

**Motivation to Switch to Keystone**
- A shareable professional profile that makes him look credible to new customers
- The knowledge base capturing real technical experience that currently lives only in his head

**Risk of Churn**
- Speed and simplicity are non-negotiable — same as Jeremie
- If the app does not feel like it belongs in his daily workflow within the first week
  he will not build the habit
- If Jeremie stops using it Jean will stop too — their behavior influences each other equally

**First Feature That Will Hook Him**
The WhatsApp follow-up and profile features — same as Jeremie. Both technicians
are equally technical and equally organized. They will adopt together, influence
each other equally, and find value in all five features at the same pace.
Neither one leads the other in adoption.

---

## Persona 3 — The Future Technician (V2/V3 Reference)

**Role:** Standard Technician — Future Platform User
**Archetype:** Independent Tradesperson Seeking Credibility and Growth

This persona does not use Keystone in V1. Documented here so architecture
and data model decisions in V1 do not accidentally make V2 harder to build.

| Field | Detail |
|---|---|
| Age Range | 18-45 |
| Occupation | Independent locksmith or related technical service worker in Ghana |
| Technical Proficiency | Low-Medium — basic smartphone user, WhatsApp daily |
| Primary Device | Android smartphone — entry level to mid range |
| Location | Greater Accra, Kumasi, Takoradi |
| Work Context | Self-employed, heard about Keystone from another technician |

**Goals**
- Join a trusted platform that makes them look more professional
- Get access to the same tools Jeremie and Jean use
- Be part of a verified network that customers trust

**Motivation to Join Keystone**
- Saw Jeremie or Jean's professional WhatsApp follow-up and wanted the same
- Was referred directly by a founding technician
- Wants the credibility of operating under the Keystone brand

**What They Need That V1 Does Not Have**
- An onboarding and application flow
- Validation and approval by founding technicians
- Access to a shared knowledge base across technicians
- Team collaboration features

**Why This Persona Is Documented Now**
Every data model decision in V1 must support this persona eventually.
User accounts must be designed for multi-tenancy from day one even though
only two users exist in V1.

---

## Persona 4 — The Customer (Passive — V1)

**Role:** End Customer — Passive Recipient
**Archetype:** Urban Ghanaian in need of locksmith services

This persona does not use the app directly in V1. They receive value
passively through WhatsApp messages sent by the technician.

| Field | Detail |
|---|---|
| Age Range | 25-55 |
| Occupation | Any — vehicle owner, homeowner, small business owner |
| Technical Proficiency | Low-Medium — WhatsApp user, basic smartphone |
| Primary Device | Android smartphone |
| Location | Greater Accra and surrounding areas |

**Goals**
- Get their lock or security problem fixed quickly and affordably
- Feel confident the technician they hired is professional and trustworthy
- Have a way to contact the same technician again when needed

**Current Experience Without Keystone**
- Finds a technician through a friend's referral or a WhatsApp group
- Has no way to verify the technician's credentials before hiring
- After the job is done loses the technician's contact or forgets who did the work
- Never receives any follow-up from the technician

**Experience With Keystone (Passive)**
- Receives a professional WhatsApp message after the job summarizing what was done
- Has the technician's contact saved from the follow-up message
- Receives a maintenance reminder months later — feels looked after
- Naturally becomes a repeat customer because the relationship was maintained

**Why This Persona Is Documented Now**
In V3 this persona becomes an active user with a customer-facing interface.
The data collected about customers in V1 must be structured to support
a customer account system in V3 without a data migration.

---

## Validation Checklist
- [x] At least 2 personas defined — 4 personas covering all user types
- [x] Each persona has a clear goal the product directly addresses
- [x] Each persona has frustrations the product will NOT solve in V1
- [x] No two personas are identical in behavior or motivation
- [x] Each persona is grounded in market research from Document 02
- [x] Churn risk is defined for each active persona
- [x] Future personas documented to protect architecture decisions
- [x] Jeremie and Jean confirmed as equally technical and equally organized
