# Salary Negotiation — My Leverage Points

> **Status**: Draft — keep adding evidence from daily journal entries  
> **Created**: 12 Mar 2026  
> **Audience**: Ben (CEO of SNDQ)  
> **Ben's values**: Business value delivery, shipping fast, not obsessed with code scalability  

---

## Negotiation Context

Ben is the CEO. He thinks in **business outcomes** and **delivery speed**, not in code quality or architecture purity. The negotiation must be framed in his language:

- "I shipped X features across Y modules" — NOT "I refactored the codebase"
- "I fixed a blocker that was stopping all deployments" — NOT "I resolved a heap memory issue"
- "I'm reducing build time so the team ships faster" — NOT "I found a circular dependency"

**Rule**: Every point must answer **"So what? How does this help the business?"**

---

## Leverage Point 1: Fast & Reliable Delivery

_Ben cares about this THE MOST._

### Evidence from journal:
- **Mar 08**: Shipped accounting table UI for supplier — made independent UI decisions without waiting for designer, zero delay
- **Mar 09**: Delivered work across 2 modules in one day (Detail Accounting table + Contact representative type)
- **Mar 10**: Shipped 2 features to staging in a single day (Detail Account Floating Sheet + Contact new representative)
- **Mar 12**: Launched Notes at Table Row across **3 modules** (Building, Contact, Supplier) in one release

### Talking point for Ben:
> "Within my first week, I was already shipping features to staging independently — multiple features per day, across multiple modules. I don't wait for others to unblock me, I find ways to keep moving."

### TODO — keep collecting:
- [ ] Count total features shipped per week
- [ ] Track turnaround time: assigned → staging → production
- [ ] Note any features delivered ahead of schedule

---

## Leverage Point 2: Unblocking the Team (Multiplier Effect)

_Bens hould see you as someone who makes the WHOLE TEAM faster, not just yourself._

### Evidence from journal:
- **Mar 12**: Fixed out-of-heap memory build error — without this, **no one on the team could deploy anything to production**
- **Mar 12**: Investigating slow build caused by circular dependencies — this affects every developer's wait time, every day
- **Mar 08**: Made UI decisions independently without designer — didn't become a bottleneck for the team

### Talking point for Ben:
> "I don't just deliver my own tasks. I fix problems that block the entire team. The build was broken — no one could deploy. I fixed it. The build is slow — every developer waits. I'm investigating and fixing the root cause. When I improve the pipeline, every engineer on the team ships faster."

### TODO — keep collecting:
- [ ] Track how many developers were unblocked by your fixes
- [ ] Estimate time saved across the team (e.g., "5 devs × 10 min saved per build × 20 builds/day = X hours/week saved")
- [ ] Note any time you helped a teammate directly (code review, pairing, answering questions)

---

## Leverage Point 3: Independence & Low Maintenance

_Ben doesn't want to babysit engineers. You cost him zero management overhead._

### Evidence from journal:
- **Mar 08**: Made UI decisions independently — no designer bottleneck, no manager approval needed
- **Mar 08**: Proactively connected with the designer — built relationship without being told to
- **Mar 09**: Learned FinTech domain (double-entry accounting) on own initiative — understands the business context without needing it explained
- **Mar 12**: Discovered refactoring pattern on own — didn't need a tech lead to tell you how to solve the architecture problem

### Talking point for Ben:
> "You don't need to manage me. I understand the product domain, I make decisions independently, I proactively build relationships with the team, and I solve architecture problems without waiting for guidance. I'm a self-driving engineer."

### TODO — keep collecting:
- [ ] Note every time you made a decision without asking
- [ ] Note every time you proactively identified a problem before being told
- [ ] Track how often you need 1:1 guidance vs how often you just deliver

---

## Leverage Point 4: Deep Frontend Expertise (Hard to Replace)

_Frame this as: "If I leave, it's hard and expensive to find someone with this combination."_

### Evidence:
- Deep knowledge of React, TypeScript, Next.js, performance optimization, system design
- Found and diagnosed complex issues others couldn't: circular dependency between React Hook Form + Zod, multiple Zod version conflicts, heap memory overflow
- Continuously learning: research repository, books indexed, GreatFrontEnd system design playbook
- Discovered scalable architecture patterns (Compound Pattern + Module-Specific Component extraction)

### Talking point for Ben:
> "I bring deep frontend expertise that directly impacts delivery speed. I found a build-breaking bug that no one else caught. I'm finding the root cause of slow builds that cost the whole team time. And I'm discovering patterns that will let us build new modules faster in the future. This kind of expertise is hard to hire for — most frontend developers can build features, but few can diagnose and fix the infrastructure underneath."

### TODO — keep collecting:
- [ ] List specific bugs/issues you found that others missed
- [ ] Track knowledge-sharing contributions (docs, tech talks, code reviews)
- [ ] Research market rate for Senior Frontend Engineers with this skillset in your location

---

## Leverage Point 5: In-Country Commitment

_Frame as: reliability, availability, and alignment — not just "I'm physically here."_

### Talking point for Ben:
> "I'm committed to being here — same timezone, available for urgent issues, present for team events and critical meetings. You get real-time collaboration without the friction of offshore time gaps. And I'm invested in the long-term success of this product."

### TODO — keep collecting:
- [ ] Note any urgent situations where your local presence mattered
- [ ] Compare against the cost/delay of hiring offshore alternatives

---

## Summary: The Pitch to Ben (Draft)

_Refine this as you collect more evidence._

> "In [X weeks], I've shipped [Y features] across [Z modules], fixed a critical build blocker that was stopping all deployments, and I'm actively improving the build pipeline so the entire team ships faster. I do all of this independently — you don't need to manage me, and I proactively solve problems before they become blockers.
>
> I bring deep frontend expertise that's hard to find: I diagnose complex infrastructure issues, I understand the business domain, and I'm investing in patterns that will accelerate future development.
>
> I'd like to discuss my compensation to reflect the value I'm delivering."

---

## Negotiation Tactics (for the conversation)

1. **Never give the first number** — let Ben anchor first
2. **Frame everything as value delivered** — "I ship fast, I unblock the team, I cost zero management overhead"
3. **Use your journal as data** — "In my first 2 weeks, I shipped X features, fixed Y blockers, touched Z modules"
4. **Negotiate the whole package** — base salary, bonus, equity, learning budget, remote flexibility, title
5. **Timing** — negotiate after a successful delivery week or when you've just saved the team from a major blocker
6. **Be collaborative** — "I want to find something that works for both of us"
7. **Silence is powerful** — after making your ask, stop talking and wait
8. **Have a BATNA** — know your alternatives (other offers, freelance rate, market rate)

---

## Market Data (TODO)

- [ ] Check [levels.fyi](https://www.levels.fyi) for your role + location
- [ ] Check [Glassdoor](https://www.glassdoor.com) salary data
- [ ] Check LinkedIn Salary Insights
- [ ] Ask peers in similar roles (confidentially)

---

## Evidence Log

_Every time you do something notable at SNDQ, add a one-liner here. Pull from your daily journal's Business Impact sections._

| Date | What happened | Business impact |
|------|--------------|-----------------|
| Mar 08 | Shipped supplier accounting table UI independently | Delivered without designer bottleneck, zero delay |
| Mar 09 | Delivered across 2 modules in one day | High throughput, broad ownership |
| Mar 10 | Shipped 2 features to staging in one day | Fast turnaround, features ready for QA quickly |
| Mar 12 | Launched Notes at Table Row across 3 modules | Cross-platform feature in a single release |
| Mar 12 | Fixed out-of-heap memory build blocker | Unblocked the entire team's ability to deploy |
| Mar 12 | Investigating slow build root cause | Will multiply the whole team's shipping speed |
| Mar 12 | Discovered scalable refactoring pattern | Future modules will be faster and cheaper to build |
| Mar 13 | Shipped Toolbar component to staging with overflow fix | Users always have access to all filters — UX improvement across the platform |
| Mar 13 | Started export PDF & XLSX for 4 accounting reports | Directly enables financial reporting for accountants and managers |
| Mar 13 | Established reusable compound component methodology | Next similar components will be built 2-3x faster |
| Mar 14 | Near-complete export PDF & XLSX for 3 accounting reports | Self-serve financial reporting for accountants, eliminates manual data extraction |
| Mar 14 | Pair testing with BA + Customer Support | Validated export against real business needs — prevents costly post-release rework |
| Mar 14 | Created backend enhancement task from pair testing | Proactive cross-layer ownership, keeps delivery pipeline moving |
| Mar 16 | Refactored Assign Payment flow to floating sheet | In-context payment workflow reduces friction in most frequent accounting action |
| Mar 16 | Role-specific UX for steward and syndic | Tailored experience reduces confusion and support overhead |
| Mar 16 | Organized skeleton loading for building dashboard | Improved perceived performance for the most-used page in the platform |
| Mar 16 | Provision Fund with in-context assign payment | Accountants handle fund transactions + payments in one place, no navigation |
| Mar 17 | Account Invoice overview with floating sheet details | Invoice visibility at a glance, drill-down without leaving dashboard |
| Mar 17 | Quick Access blocks for sub-accounting pages | Reduces clicks to reach daily-use pages, compounds into time savings |
| Mar 17 | Sidebar building navigation (My Buildings + Workspace) | Eliminates back-to-list navigation for multi-building managers — core daily workflow |
| Mar 17 | Building dashboard as command center | Cross-feature integration: assign payment + invoices + quick access + sidebar in one hub |
