# DOCUMENT 01 — PROBLEM BRIEF
### Project: Keystone
### Tagline: The business backbone for independent locksmith technicians in Ghana
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 1.1 Problem Statement

Independent locksmith technicians in Ghana operate entirely from memory and informal phone contact systems. They have no structured way to record customer history, document technical solutions they discover on difficult jobs, or follow up with past customers to generate repeat business. As a result, valuable technical knowledge is lost after every job, customers are forgotten after payment, and business growth depends entirely on chance referrals rather than any deliberate system. The consequence is a skilled technician who remains small and invisible not because of lack of talent but because of lack of organization.

---

## 1.2 Affected Users

**Primary Users — The Technicians**
Independent locksmith technicians operating in Ghana. The founding technicians are Jeremie and Jean, specifically those who:
- Work alone or in small informal partnerships
- Use only their personal phone to manage all customer interactions
- Have real technical skill but no business management system
- Rely on WhatsApp and social media as their only growth channels
- Are familiar with smartphones and WhatsApp but have never used a business management tool

**Secondary Users — The Customers**
Ghanaian individuals and small businesses who need locksmith services including:
- Vehicle owners needing car lock and key programming
- Homeowners and businesses needing door lock installation or repair
- Homeowners and businesses needing smart lock installation
- These users do not interact with the app directly in V1 but receive its outputs through WhatsApp

**Anti-Audience — Who This Is NOT For**
- Large formal security companies with existing management software
- Technicians outside the locksmith and related technical services space
- Customers looking to book services through a marketplace in V1

---

## 1.3 Pain Points

**Functional Pain:**
1. Customer phone numbers are saved with no context — no record of what work was done, where, when, or how much was charged
2. Technical solutions discovered on difficult jobs — bypass codes, unusual techniques, special tools used — are never recorded and are lost permanently after the job
3. There is no follow-up system — once a customer pays, they are never contacted again unless they call first
4. When two technicians work together they have no shared system — each manages their own informal records separately
5. There is no professional profile or portfolio — when a new customer asks what services they offer, the technician explains verbally every single time

**Emotional Pain:**
6. Technicians feel their skills are invisible — they do excellent work but have no way to show it or build a reputation systematically
7. There is a constant anxiety about losing a customer number or forgetting important job details

---

## 1.4 Current Alternatives

**Phone Contacts App**
- What it does well: Saves names and numbers quickly
- Where it falls short: No job history, no notes per customer, no follow-up, no organization by service type

**WhatsApp and Social Media (Facebook and Instagram)**
- What it does well: Reaches existing contacts and some new audiences, easy to share photos of work done, direct communication
- Where it falls short: No organization, posts disappear in feeds, no customer history, no follow-up system, growth depends on algorithm and personal network size, no way to track which customer came from which post

**Memory**
- What it does well: Fast access for recent jobs
- Where it falls short: Fades over time, unreliable for technical details, completely lost if phone is damaged or changed

**Paper Notebooks**
- What it does well: Simple, always available
- Where it falls short: Not searchable, easily lost, cannot send follow-ups, not shareable

**Western Field Service Tools (Jobber, Workiz, ServiceTitan)**
- What they do well: Comprehensive job management
- Where they fall short: Expensive, complex, built for Western markets, require reliable internet, assume a formal business structure that does not match how Ghanaian independent technicians operate

---

## 1.5 Core Solution

A simple, mobile-first business management tool built specifically for independent locksmith technicians in Ghana that allows them to record every customer and job, save technical knowledge discovered on difficult jobs, and automatically follow up with customers through WhatsApp — turning every completed job into a foundation for repeat business and professional reputation building.

---

## 1.6 Value Proposition

**What it does that nothing else does:**
- Combines customer management, technical knowledge saving, and WhatsApp follow-up automation in one tool designed for the Ghanaian informal technical services market
- The knowledge base feature is unique — no existing tool lets a technician save a car programming bypass code and find it again by job type next time

**What it does faster:**
- Logging a job takes under 60 seconds
- Sending a professional follow-up to a customer requires one tap
- Finding a past customer or technical note is instant search rather than scrolling through contacts

**What the technician no longer has to do:**
- Rely on memory for customer history and technical solutions
- Manually compose follow-up messages
- Explain their services from scratch to every new customer
- Lose repeat business because they forgot to follow up

**Why a Ghanaian technician will use this over alternatives:**
- Works entirely through a smartphone they already own
- Integrates with WhatsApp which they already use daily
- Requires no formal business registration or complex setup
- Built for how they actually work not how a Western business works

---

## 1.7 Assumptions Being Made

**About user behavior:**
- Technicians will log jobs consistently if the process takes under 60 seconds
- Technicians value having their technical solutions saved and searchable
- Customers respond positively to professional WhatsApp follow-ups from their technician
- Technicians are willing to share a profile link with new customers via WhatsApp

**About the market:**
- There is no existing tool serving this specific combination of needs for Ghanaian independent technicians
- Word of mouth among technicians will drive organic adoption once the founding members demonstrate value
- The franchise model will be attractive to independent technicians who want to operate under a trusted brand

**About technology:**
- Technicians have consistent enough smartphone and mobile data access to use a mobile app daily
- WhatsApp Business API or deep link integration is technically feasible for the follow-up feature
- The app can function with intermittent internet connectivity

**About timing:**
- The informal technical services sector in Ghana is large enough and underserved enough to support this product
- The two founding technicians are committed enough to use the app consistently and serve as validators for the platform

---

## 1.8 The Bigger Vision (Context for Architecture Decisions)

While V1 is a personal tool for two technicians, every technical decision must quietly support what this becomes:

V1 — Personal tool for Jeremie and Jean (founding technicians)
V2 — Shared platform for their growing team
V3 — Franchise model: other technicians join under the Keystone brand
V4 — Full SaaS platform for the Ghanaian technical services industry

The founding technicians are not just users. They are industry founders and the face of the platform. Every technician who joins in V3 and beyond operates under their brand, their standards, and their validation. Their company is the one that scales — Keystone is the infrastructure that makes that scaling possible.

---

## Validation Checklist
- [x] Only one core problem is defined
- [x] The problem is specific and has a measurable impact
- [x] The solution directly addresses the problem
- [x] At least one assumption is listed
- [x] No features are described — only outcomes
- [x] The bigger vision is documented for architecture awareness
