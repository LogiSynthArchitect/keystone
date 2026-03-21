# Keystone Content Strategy — V1 Snapshot

**Status:** Living document. V1 content roadmap. Grows with V2 features, user stories, new lessons.

What to post on LinkedIn. What to keep private. How to build the Keystone story.

---

## Part 1: What We CAN Share (V1 Story)

### The Journey — Act as a Founder Building in Public

**What's shareable:**
- The why (why locksmiths need this)
- The how (architecture, tech choices, lessons learned)
- The bugs we hit and fixed (real debugging stories)
- Time-to-market (built in 6 weeks with 2 pilot users)
- The data (X jobs logged, Y customers tracked, Z profile views)

**Example posts:**

**Post 1: The Problem**
```
We built Keystone for locksmiths in Accra who lose customer data
when their phone crashes. Offline-first sync was the answer.

Here's how offline-first sync works:
1. Write to local storage immediately
2. User sees instant feedback ("saved")
3. Sync to server in background
4. User never waits for internet

Result: Job logged in 2 seconds, synced in 10.
```

**Post 2: The Bug (Debugging Story)**
```
We had a nasty bug: archived jobs would reappear after sync.

Root cause: Remote data was overwriting local pending state.
User archived job offline. Next sync: remote data says job exists,
overwrites local "archived" flag back to active.

The fix: Check local state FIRST. If there's a pending action,
don't overwrite it with remote state.

Lesson: In offline-first apps, local state is source of truth
until sync confirms. Remote doesn't override pending writes.

#FlutterDev #OfflineFirst
```

**Post 3: Architecture Decision**
```
Why we chose Supabase + Hive for Keystone:

Supabase: PostgreSQL + RLS + Realtime (easy, powerful)
Hive: Local key-value store (fast, offline-capable)

Together they handle the offline-first requirement perfectly.

Would I choose differently? For V2, maybe add analytics
(Mixpanel) and file storage optimization (S3). But core
choice holds up.

Stack: Flutter + Supabase + Hive + Vercel + GitHub Actions
```

**Post 4: The Lesson**
```
Building for 2 pilot users taught us more than designing
for 1M users ever could.

Jeremie logs 5-10 jobs a day. Jean handles complex service calls.
Within 2 weeks, we found:
- Keyboard focus bug on "0" keystroke
- Sync status stuck on failure
- Profile URL slug matching edge case

All real problems from real usage. Impossible to discover
in a test lab.

V1 lesson: Ship small, learn fast, iterate with real users.
```

---

## Part 2: What We CANNOT Share

### The Hard Lines

**❌ Never share:**
- User phone numbers (never share — keep in private records only)
- Real customer names or details
- Business metrics (revenue, pricing, margins)
- Real Supabase project credentials (even public project IDs are borderline)
- Internal bug fixes before they're merged (security)

**⚠️ Share carefully:**
- Screenshots: Blur phone numbers, customer names
- Data metrics: Say "2 pilot users" not "Jeremie and Jean"
- Timelines: "Built in 6 weeks" is OK, "shipped March 15" is OK, "scheduled for March 15" reveals roadmap

---

## Part 3: V1 Content Calendar

**Theme per month (based on actual V1 development):**

### Month 1: Inception & Architecture (Mar 1-15)
- Why we're building Keystone
- Problem statement (locksmith data loss in Accra)
- Tech stack choice (Flutter + Supabase)
- First PR merged

**Content format:** 1 introductory thread, 1 architecture post, 2-3 shorts

### Month 2: Feature Build-Out (Mar 16-30)
- Job logging feature live
- Customer deduplication algorithm
- Offline sync implementation
- First 2 users onboarded

**Content format:** 2 feature demos (screenshots), 1 technical deep-dive, 1 milestone post

### Month 3: Bugs & Fixes (Apr 1-15)
- Sync status stuck (BUG-001)
- Keyboard focus loss on "0" (BUG-003)
- Archive job reappearing (BUG-004)
- How we debugged each

**Content format:** 3 "Bug found and fixed" threads, 1 testing strategy post

### Month 4: Polish & Public Launch (Apr 16-30)
- Web profile page live
- Light theme redesign
- Public share links working
- LinkedIn roadmap published

**Content format:** 1 web launch announcement, 1 design evolution post, 1 public launch thread

---

## Part 4: Content Formats That Work

### Format 1: The Technical Thread (High Value)

**Structure:**
```
Opening: Problem statement in 1 sentence
Context: Why this matters (1-2 sentences)
Solution: How we solved it (3-5 points)
Code snippet: (optional) 1 small code example
Lesson: What we learned (1 sentence)
CTA: "Follow for more"
```

**Example:**
```
Thread: We found a critical bug in offline sync. Here's how we debugged it.

Problem: Jobs created offline never synced to the server.

Why it mattered: Users thought their data was gone. Trust killer.

Investigation:
1. Checked local Hive storage — data was there ✓
2. Checked network requests — POST was firing ✓
3. Checked server logs — insert was failing silently ✗
4. Root cause: Foreign key constraint on user_id

The issue: We were passing auth.uid() instead of the internal users.id.
Supabase has two IDs — auth.uid() for authentication, users.id for data.
Mix them up = constraint error.

The fix: Always use currentUserProvider.id (internal), never auth.uid().

Lesson: In multi-layer auth systems, map your IDs clearly.
```

**Hashtags:** #FlutterDev #BugFix #Supabase #Debugging

---

### Format 2: The Decision Post (Medium Value)

**Structure:**
```
Decision: What we chose
Why: Context + constraints
Trade-offs: What we gave up
Result: Outcome after 2 weeks
```

**Example:**
```
We chose offline-first sync over real-time sync.

Why: Locksmiths work on job sites with spotty internet.
Waiting for server response means 5-10 second delays.
Offline-first means instant feedback.

Trade-off: More complex code. Sync conflicts. Local cache management.

Result: After 2 weeks, Jeremie says "it feels fast."
Jobs logged in <2 seconds even on 2G.

Worth it? Yes. Would do again.
```

**Hashtags:** #Architecture #FlutterDev #ProductDesign

---

### Format 3: The Learning Post (Highest Impact)

**Structure:**
```
Situation: What happened
Mistake: What we got wrong
Realization: The insight
Application: How to apply it
```

**Example:**
```
We shipped without environment separation. Big mistake.

Situation: Someone (maybe me) ran a migration on production database
by accident. Deleted 3 weeks of test data.

The mistake: Staging and production were in the same project.
No confirmation prompts. No warnings.

The realization: Separation isn't "nice to have." It's foundational.
One typo should never touch production.

How to apply it:
- Default to staging (not production)
- Explicit flags required for prod
- Document it in your system instructions
- Code review catches violations

This cost us a day of recovery but saved us from bigger failures later.
```

**Hashtags:** #DevOps #Lessons #SoftwareEngineering

---

## Part 5: Monthly Metrics to Share

Track and post monthly:

- **Jobs logged:** Total count (anonymized)
- **Active users:** Count only
- **Features shipped:** List of features added/fixed
- **Bugs fixed:** Count
- **Docs updated:** Count (shows documentation rigor)
- **Test coverage:** % or count

**Example post:**
```
Keystone V1 — Month 1 Recap

Jobs logged: 127
Active users: 2
Features shipped: 3 (logging, history, profiles)
Bugs fixed: 12
Docs added: 40 pages
Test coverage: 36 passing tests

On pace for V1 release in 6 weeks. Building in public.
Follow for weekly updates.
```

---

## Part 6: What NOT to Post (But OK to Share Privately)

**Keep in repos, not LinkedIn:**
- Detailed Supabase schema (security through obscurity)
- Full error traces (reveals attack surface)
- Performance benchmarks vs competitors (invites legal review)
- Internal debates (looks indecisive)
- Roadmap with dates (commits you publicly)

**OK to mention, not OK to detail:**
- "We hit a critical sync bug" → yes
- "Sync bug was in RPC function batch_sync_jobs line 27" → no
- "2 pilot users" → yes
- "Jeremie + Jean from Accra" → no

---

## Part 7: Building Your Audience

### The Narrative Arc

**Act 1: The Problem** (Week 1-2)
- What problem are we solving?
- Who are we solving it for?
- Why does it matter?

**Act 2: The Solution** (Week 3-8)
- Here's what we built
- Here's how it works
- Here's what we learned

**Act 3: The Outcome** (Week 9+)
- Real users, real impact
- Lessons that apply to others
- What's next (V2 roadmap, not commitments)

### Hashtag Strategy

Mix hashtags for reach:
- **Vertical:** #LocksmiththTech, #Ghana, #AfricaTech (niche audience)
- **Technical:** #FlutterDev, #Supabase, #OfflineFirst (developer audience)
- **Broader:** #Entrepreneurship, #ProductBuilding, #SoftwareEngineering (wider reach)

### Call-to-Action

Every post ends with:
- "Follow for next week's update"
- "Thoughts on this approach?"
- "Have you solved this differently?"
- Link to GitHub repo

---

## Part 8: Metrics to Track

**LinkedIn post metrics:**
- Impressions: How many saw it?
- Engagement: Likes, comments, reposts
- Click-through: How many visited the link?
- Follower growth: Did this post gain followers?

**Keystone app metrics (safe to share):**
- Monthly active users (not names)
- Jobs per user
- Sync success rate
- Profile link clicks
- WhatsApp follow-up conversion

**Track these and post monthly:** "Month X recap: X jobs, Y users, Z bugs fixed"

---

## Part 9: Evolving the Strategy (V2 & Beyond)

### What Changes with V2

**New content themes:**
- Play Store launch strategy
- SMS OTP implementation (security lessons)
- Scaling from 2 to 50 users
- Admin panel design
- Analytics integration
- Multi-language support

**New metrics to share:**
- Play Store rating
- App store downloads
- New user retention
- Feature usage stats
- Community feedback themes

**New formats:**
- User testimonials (anonymized)
- Video demos
- Live coding sessions (if you're into that)
- Podcast appearances
- Conference talks

### When to Update This Document

- After V2 launches (new features, new lessons)
- Quarterly if something in V1 changes
- Monthly to add this month's posts
- Whenever a new major bug/lesson emerges

---

## Summary: Why Post About Keystone?

**For others:**
People building for developing countries need to know offline-first works. Your journey saves them 3 months.

**For you:**
Recording decisions + lessons = your playbook for V2, V3, next project.

**For business:**
Founder visibility on LinkedIn → speaking opportunities → partnership requests → funding conversations.

**For team:**
Showing progress builds momentum. Real people see it working. They want to help.

---

## Quick Posting Checklist

Before posting:
- [ ] No real phone numbers
- [ ] No customer/user names
- [ ] No credentials (keys, URLs, tokens)
- [ ] Screenshot blurred if needed
- [ ] Technical claim is accurate
- [ ] Applicable lesson for the audience
- [ ] Hashtags 3-5 relevant ones
- [ ] CTA included (follow, comment, link)
- [ ] Tone: Learning, not boasting

---

**Last Updated:** Session 30 (March 20, 2026)

**Next Review:** After first 5 LinkedIn posts (April 2026) or V2 launch

**Content Calendar:** Add your actual posts below (monthly update)

```
# V1 Content Calendar — ACTUAL POSTS

## March 2026
- [ ] Post 1: [Title] (Impressions: X, Engagement: Y%)
- [ ] Post 2: [Title]

## April 2026
(To be filled in)

## V2 Content Calendar (TBD)
```
