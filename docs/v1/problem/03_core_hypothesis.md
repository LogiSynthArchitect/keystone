# DOCUMENT 03 — CORE HYPOTHESIS
### Project: Keystone
**Required Inputs:** Document 01 — Problem Brief, Document 02 — Market Research
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 3.1 Product Hypothesis

We believe that independent locksmith technicians in Ghana — starting with Jeremie and Jean
— will use Keystone daily to record their jobs, save technical knowledge, and follow up with
customers through WhatsApp, because it removes the mental burden of remembering everything
and replaces it with a simple organized system, which will result in more repeat customers,
recovered technical knowledge, and a growing professional reputation that attracts new business.

---

## 3.2 User Behavior Assumptions

**How often will they use it?**
- Jeremie and Jean will open the app at least once per working day
- They will log every job completed — minimum 1 job per day between the two of them
- They will use the knowledge base feature at least once per week when they encounter
  a difficult or unusual job

**What will trigger them to use it?**
- Completing a job triggers job logging
- Encountering a difficult technical problem triggers saving a knowledge note
- Finishing a job triggers sending a WhatsApp follow-up to the customer
- A customer calling back triggers checking their job history in the app

**How much effort are they willing to invest to get started?**
- Maximum 10 minutes of onboarding before they expect to see value
- If the first job cannot be logged in under 60 seconds, adoption risk is high
- They will not read instructions — the app must be intuitive enough to use without guidance

**Will they pay for it?**
- Not in V1 — Jeremie and Jean are founding members and use it free
- Future technicians joining the platform will pay a small monthly fee in local currency
- Payment must be through MTN Mobile Money or similar — not credit card

---

## 3.3 Market Assumptions

**Discovery:**
- In V1 there is no marketing — Jeremie and Jean are the only users
- In V2 and V3 new technicians discover Keystone through word of mouth from Jeremie and Jean
- The founding technicians sharing their professional WhatsApp follow-ups with customers
  will generate curiosity from other technicians who see the messages

**Conversion:**
- Any technician who sees Keystone working for Jeremie and Jean in person will want to try it
- The biggest conversion driver is seeing a real result — a repeat customer, a recovered
  technical solution, a professional follow-up message
- Estimated conversion rate from demo to signup: 40-60% for technicians who see it live

**Retention:**
- If a technician logs more than 5 jobs in their first week, they will not stop using the app
- The knowledge base becomes a retention lock — once a technician has saved 10+ technical
  notes, the app becomes irreplaceable to them
- Expected 30-day retention for active users: 70%+
- Expected 90-day retention for users who have saved knowledge notes: 85%+

**Word of mouth:**
- Every WhatsApp follow-up message sent by a technician is a passive advertisement for
  Keystone — customers who receive professional messages will ask their technician about it
- Every technician who sees another technician using Keystone professionally will ask about it
- Expected referral coefficient: 1 active technician refers 1-2 new technicians within 90 days

---

## 3.4 Technical Assumptions

**What the product depends on:**
- Android smartphone with minimum 2GB RAM — standard on Tecno, Itel, Samsung in Ghana
- Mobile data connection for syncing — minimum 3G
- WhatsApp installed on the same device — near-universal in urban Ghana
- The app must work with intermittent connectivity — jobs logged offline must sync when
  connection returns

**Third-party integrations assumed to work reliably:**
- WhatsApp deep links (wa.me) for V1 follow-up messages — no API approval needed
- Firebase or Supabase for backend — reliable and available in Ghana
- Google Maps or OpenStreetMap for job location tagging

**Scale required from day one:**
- V1: 2 users, minimal infrastructure needed
- V2: Up to 50 users, standard cloud hosting sufficient
- V3: Up to 500 users, architecture must support multi-tenancy from day one
  even though it is not needed immediately

---

## 3.5 Success Metrics by Phase

**Phase 1 — Validation (0-3 months)**
Goal: Confirm that Jeremie and Jean find genuine value in Keystone

- [ ] Both technicians open the app at least 5 days per week for 8 consecutive weeks
- [ ] At least 20 jobs logged between the two of them in the first month
- [ ] At least 1 repeat customer contacts either technician because of a WhatsApp follow-up
- [ ] At least 5 technical knowledge notes saved in the knowledge base
- [ ] Both technicians say unprompted that the app has made their work easier

The last metric is the most important. If Jeremie and Jean do not say it has made a
difference without being asked, the product has not solved the real problem yet.

**Phase 2 — Early Growth (3-12 months)**
Goal: Confirm that other technicians want what Jeremie and Jean have

- [ ] At least 10 additional technicians using Keystone actively
- [ ] At least 5 technicians logging jobs daily
- [ ] At least 3 technicians report a repeat customer directly from a WhatsApp follow-up
- [ ] Zero technicians have churned after logging more than 10 jobs
- [ ] Jeremie and Jean have validated and approved at least 5 new technicians

**Phase 3 — Maturity (12+ months)**
Goal: Keystone is the recognized tool for professional locksmith technicians in Ghana

- [ ] 100+ active technicians on the platform
- [ ] Technicians are paying a monthly fee in Mobile Money without friction
- [ ] The Keystone brand is known among locksmith technicians in Accra and Kumasi
- [ ] Jeremie and Jean's company is earning passive income from technicians on the platform
- [ ] At least one technician has been removed from the platform for quality violations —
      proving the validation system works

---

## 3.6 Failure Conditions

**Failure Condition 1 — No daily usage after 30 days**
If either Jeremie or Jean stops using the app daily within the first 30 days without
an external reason, the core loop is not valuable enough.
Action: Go back and watch them work. Find what they actually need.

**Failure Condition 2 — Jobs not being logged**
If fewer than 15 jobs are logged in the first month between two active technicians,
the logging experience is too slow or too complicated.
Action: Simplify job logging to the absolute minimum fields required.

**Failure Condition 3 — Knowledge base not being used**
If no technical knowledge notes are saved after 60 days, the feature is either not
discoverable or not solving a real pain.
Action: Observe Jeremie and Jean on real jobs. Is the feature too hidden?

**Failure Condition 4 — No repeat customers from follow-ups**
If after 90 days not a single customer has returned because of a WhatsApp follow-up,
the follow-up feature is either not being used or not compelling enough.
Action: Review the follow-up message templates. Talk to customers directly.

**Failure Condition 5 — No word of mouth after 6 months**
If after 6 months no other technician has asked about Keystone after seeing Jeremie
and Jean use it, the product is not visibly differentiated enough to generate curiosity.
Action: Reconsider the growth strategy. Possibly invest in direct outreach.

---

## 3.7 Riskiest Assumptions (Ranked)

**Risk 1 — HIGHEST: Consistent daily usage**
The assumption that Jeremie and Jean will log every job consistently is the riskiest.
Behavior change is hard. The informal sector thrives on habits that require zero effort.

How to test cheaply: Before building, ask Jeremie and Jean to send you a WhatsApp
message every time they complete a job for two weeks. If they do it consistently,
they will log it in an app. If they forget after three days, the onboarding experience
needs to be dramatically simpler.

**Risk 2 — MEDIUM: WhatsApp follow-up actually drives repeat business**
We assume customers respond positively to follow-up messages. In Ghana, unsolicited
messages can sometimes be seen as spam or pressure.

How to test cheaply: Have Jeremie and Jean manually send a simple WhatsApp follow-up
to their last 10 customers today without the app. See how many respond positively.
If more than 3 respond well, the assumption is validated.

**Risk 3 — LOWER: Other technicians want to join the platform**
The franchise model assumes other technicians will want to operate under the Keystone
brand. Some technicians may prefer to remain completely independent.

How to test cheaply: After 3 months of Jeremie and Jean using Keystone, show it to
3 other technicians they know. Ask them directly — would you pay to use this and be
part of this network?

---

## Validation Checklist
- [x] The product hypothesis is one sentence and testable
- [x] Failure conditions are specific and have clear action responses
- [x] All three riskiest assumptions have proposed cheap tests
- [x] Success metrics are defined per phase
- [x] Phase 1 success is grounded in human satisfaction not just numbers
