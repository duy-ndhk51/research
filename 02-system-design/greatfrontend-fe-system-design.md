# GreatFrontEnd — Front End System Design Playbook

> **Author**: Yangshun Tay (Ex-Meta Staff Engineer)  
> **Source**: [GreatFrontEnd Front End System Design Playbook](https://www.greatfrontend.com/front-end-system-design-playbook/introduction)  
> **Format**: Online guide  

---

## TL;DR

A comprehensive guide specifically for **Front End System Design interviews**, as opposed to traditional back-end/distributed systems design. Introduces the **RADIO framework** — a structured approach for answering front end system design questions. Covers requirements exploration, architecture design, data modeling, interface/API definition, and optimizations. Includes common mistakes, evaluation criteria, and categorized question types (Applications vs UI Components).

---

## 1. Introduction: Front End vs Back End System Design

Front end system design interviews differ significantly from back end ones. The focus shifts from distributed cloud services to **client-side architecture**, **component design**, and **API design between client and server**.

### Key Differences

| Area | Back End / Full Stack | Front End |
|------|----------------------|-----------|
| Gather requirements | Required | Required |
| Architecture entities | Distributed cloud services | Application / Component |
| Back-of-the-envelope estimation | May be required | **Not required** |
| Components of the system | Cloud services (Load balancer, DB, Cache, CDN, Message queues) | Application modules (Model, View, Controller) |
| Data model | Database schema | **Application state** |
| Type of APIs | Network (any protocol) | Network (HTTP, WebSocket) + JavaScript functions |
| Deep dive / focus areas | Scalability, Reliability, Consistency, Availability | **Performance, UX, Accessibility, i18n** |
| Less important (black box) | Client | **Server** |

### Same Question, Different Focus — Example: "Design Facebook News Feed"

- **Front End focus**: HTTP API for the feed, feed pagination implementation, post interactions, new post creation, UX and accessibility considerations
- **Back End focus**: Capacity estimation, database schema, APIs between microservices, scaling services, fan-out strategies for posts

---

## 2. Common Mistakes to Avoid

### Mistake 1: Jumping into answering immediately
Take time to gather requirements and clarify assumptions. Answering the wrong question well is worse than answering the right question poorly.

### Mistake 2: Unstructured approach
Use the **RADIO framework**. Write down each step on the whiteboard at the start. Ensure all sections are covered by the end.

### Mistake 3: Insisting on only one solution
There are always multiple ways to solve a problem with different tradeoffs. The interviewer wants to see you **identify the right tradeoffs**, not insist on one "best" solution. Even clearly bad solutions should be mentioned and explained why they are bad.

### Mistake 4: Remaining silent
Think out loud. System design interviews are **collaborative exercises**. Treat the interviewer as a coworker — bring up issues, bounce ideas, discuss solutions.

### Mistake 5: Going down a rabbit hole
Don't dive too deep into one component. Define the architecture first, then elaborate. Ask the interviewer if you should dive deeper into a specific area. Don't waste time on unimportant components.

### Mistake 6: Using buzzwords without being able to explain them
Don't throw terms like "Virtual DOM", "DOM Reconciliation", "Partial Hydration", "Streaming SSR" unless you can explain them. Using a term you can't explain is a **red flag**.

---

## 3. Evaluation Criteria (What Interviewers Look For)

### 3.1 Problem Exploration
- Identified important aspects to focus on
- Defined scope of the problem
- Gathered functional and non-functional requirements
- Asked relevant clarifying questions to minimize ambiguities
- Demonstrated thorough understanding

### 3.2 Architecture
- Scalable and reusable architecture that supports future requirements
- Practical architecture that can be implemented
- Articulated how components work together with clear APIs
- Identified components with clearly defined responsibilities
- Broke the problem into smaller, independent parts of suitable granularity

### 3.3 Technical Proficiency
- Identified areas needing special attention with proposed solutions and tradeoff analysis
- Able to dive into specific front end domain areas (Performance, Networking, HTML/CSS, Accessibility, i18n, Security, Scalability)
- Demonstrated knowledge of front end fundamentals, common technologies, and APIs

### 3.4 Exploration and Tradeoffs
- Offered various possible solutions and explained pros/cons of each
- Explained suitability given the context and requirements
- Even obviously bad solutions should be mentioned with brief explanation of why they are bad
- Do NOT insist there is only one possible solution

### 3.5 Product and UX Sense
- Considered error cases and ways to handle them
- Considered UX: loading states, performance (perceived/actual), mobile friendliness, keyboard friendliness
- Proposed a robust solution that forms the foundation of a good product

### 3.6 Communication and Collaboration
- Open to feedback and incorporates it to refine solutions
- Engaged the interviewer, asked good questions, sought opinions
- Explained complex concepts with ease
- Conveyed thoughts clearly and concisely

### Evaluation Axes × RADIO Framework Mapping

| Axis | R | A | D | I | O |
|------|---|---|---|---|---|
| Problem exploration | ✅ | - | - | - | - |
| Architecture | - | ✅ | ✅ | ✅ | - |
| Technical proficiency | - | ✅ | - | - | ✅ |
| Exploration and tradeoffs | - | ✅ | ✅ | ✅ | ✅ |
| Product and UX sense | - | - | - | - | ✅ |
| Communication and collaboration | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 4. The RADIO Framework

The core structured approach for answering front end system design questions.

```
R — Requirements Exploration
A — Architecture / High-level Design
D — Data Model
I — Interface Definition (API)
O — Optimizations and Deep Dive
```

### Time Allocation

| Step | Objective | Duration |
|------|-----------|----------|
| **R** — Requirements | Understand the problem, determine scope via clarifying questions | < 15% |
| **A** — Architecture | Identify key components and their relationships | ~20% |
| **D** — Data Model | Describe data entities, fields, and which components own them | ~10% |
| **I** — Interface | Define APIs between components, parameters, and responses | ~15% |
| **O** — Optimizations | Discuss optimization opportunities and deep dive into specific areas | ~40% |

---

### 4.1 Requirements Exploration (< 15%)

**Objective**: Understand the problem thoroughly and determine scope.

Treat the interviewer as a product manager. Ask enough questions to know what problems you're solving.

#### Key Questions to Ask

1. **What are the main use cases to focus on?**
   - E.g., "Design Facebook" → Focus on news feed, feed pagination, post creation (not the befriending flow)
   - Focus on the most **unique aspects** of the product

2. **What are the functional vs non-functional requirements?**
   - **Functional**: Basic requirements the product cannot function without (core flows)
   - **Non-functional**: Improvements like performance, scalability, good UX (product can still function without these)
   - Preferred approach: Take initiative to list requirements and get feedback/alignment from interviewer

3. **What are the core features vs good-to-have?**
   - E.g., Creating Facebook posts → Should it support photos, videos, polls, check-ins, or just text?
   - Design for core features first, then extras

4. **Other important questions:**
   - What are the performance requirements?
   - Who are the main users?
   - Is offline support necessary?
   - What devices/platforms need to be supported (desktop/tablet/mobile)?

> **Tip**: Write down the agreed requirements so you can refer to them throughout the interview.

---

### 4.2 Architecture / High-level Design (~20%)

**Objective**: Identify key components and their relationships. Focus on **client-side** architecture.

Draw diagrams — each component as a rectangle with arrows for data flow. Components can contain sub-components.

#### Common Front End Architecture Components

| Component | Responsibility |
|-----------|---------------|
| **Model / Client Store** | Where the data lives. Stores data to be presented via views. Usually app-wide. |
| **Controller** | Responds to user interactions, processes data from store in format the view expects. Not always needed for small apps. |
| **View** | What the user sees. Contains smaller subviews. Can contain client-side only state. |
| **Server** | Treated as a black box. Exposes APIs via HTTP/WebSocket. |

#### Architecture Considerations

- **Where computation should occur**: Server or client? Depends on product and context. Each has tradeoffs.
- **Separation of concerns**: Components should be modular, encapsulate functionality and data.
- Not every common component is necessary for every product.

#### Example: Facebook News Feed Architecture

```
┌─────────────────────────────────┐
│           Server                │  (Black box — exposes APIs)
└──────────────┬──────────────────┘
               │ HTTP / WebSocket
┌──────────────▼──────────────────┐
│        Client Store             │  (Feed data, User data)
└──────────────┬──────────────────┘
               │
┌──────────────▼──────────────────┐
│           Feed UI               │
│  ┌────────────────────────────┐ │
│  │    Post Composer           │ │  (UI for creating new posts)
│  ├────────────────────────────┤ │
│  │    Feed Post (list)        │ │  (Post data + interaction buttons:
│  │                            │ │   like/react/share/comment)
│  └────────────────────────────┘ │
└─────────────────────────────────┘
```

After drawing the diagram, verbally describe each component's responsibilities.

---

### 4.3 Data Model (~10%)

**Objective**: Describe data entities, fields, and which components own them.

#### Two Kinds of Client Data

**1. Server-originated data**
- Originates from a database, meant to be seen by multiple people or accessed from multiple devices
- Examples: user data (name, profile picture), user-generated data (posts, comments)

**2. Client-only data (state)**
- Only lives on the client, does not need to be sent to the server
- Two sub-types:
  - **Ephemeral data**: Temporary state (form validation, current tab, section expanded/collapsed). Acceptable to lose when browser tab closes.
  - **Data to be persisted**: User input like form field data. Must eventually be sent to server and saved to DB.

#### Example: Facebook News Feed Data Model

| Source | Entity | Belongs To | Fields |
|--------|--------|------------|--------|
| Server | `Post` | Feed Post | `id`, `created_time`, `content`, `image`, `author` (a `User`), `reactions` |
| Server | `Feed` | Feed UI | `posts` (list of `Post`s), `pagination` (pagination metadata) |
| Server | `User` | Client Store | `id`, `name`, `profile_photo_url` |
| User input (client) | `NewPost` | Feed Composer UI | `message`, `image` |

> The data model is **dynamic and iterative** — you may need to add more fields as requirements evolve during the interview.

---

### 4.4 Interface Definition / API (~15%)

**Objective**: Define APIs between components — functionality, parameters, and responses.

#### API Types in Front End

| Parts of an API | Server ↔ Client | Client ↔ Client |
|----------------|-----------------|-----------------|
| Name & functionality | HTTP path | JavaScript function |
| Parameters | HTTP GET query / POST body | Function parameters |
| Return value | HTTP response (typically JSON) | Function return value |

#### Example: Server-Client API — Fetch News Feed

| Field | Value |
|-------|-------|
| HTTP Method | `GET` |
| Path | `/feed` |
| Description | Fetches the feed results for a user |

**Parameters** (pagination):
```json
{
  "size": 10,
  "cursor": "=dXNlcjpXMDdRQ1JQQTQ"
}
```

**Response**:
```json
{
  "pagination": {
    "size": 10,
    "next_cursor": "=dXNlcjpVMEc5V0ZYTlo"
  },
  "results": [
    {
      "id": "123",
      "author": {
        "id": "456",
        "name": "John Doe"
      },
      "content": "Hello world",
      "image": "https://www.example.com/feed-images.jpg",
      "reactions": {
        "likes": 20,
        "haha": 15
      },
      "created_time": 1620639583
    }
  ]
}
```

#### Client-Client API
Written similarly — JavaScript functions or events being listened to. Describe functionality, parameters, and return values.

#### UI Component API
For component design questions, the "Interface" section discusses **customization options** (similar to React props).

---

### 4.5 Optimizations and Deep Dive (~40%)

**Objective**: Discuss optimization opportunities and dive deep into specific areas.

This is the largest section. No fixed way to proceed — select areas based on:

1. **Focus on your strengths**: Showcase domain knowledge. If you're strong in accessibility, talk about a11y pitfalls and solutions. If you're a performance expert, explain optimization techniques.

2. **Focus on important areas of the product**: E-commerce → performance is crucial. Collaborative editors → race conditions and concurrent modifications.

#### General Deep Dive Topics

| Topic | Key Considerations |
|-------|-------------------|
| **Performance** | Lazy loading, code splitting, virtualization, caching, bundle optimization, perceived performance |
| **Accessibility (a11y)** | ARIA attributes, keyboard navigation, screen reader support, focus management, color contrast |
| **Network** | Request batching, caching strategies, optimistic updates, offline support, retry logic |
| **User Experience** | Loading states, error states, empty states, skeleton screens, animations, responsive design |
| **Security** | XSS prevention, CSRF protection, Content Security Policy, input sanitization |
| **Multi-device Support** | Responsive layouts, touch vs mouse interactions, different screen sizes |
| **Multilingual Support (i18n)** | String externalization, RTL layouts, locale-specific formatting |

---

## 5. Types of Front End System Design Questions

There are two main categories: **Applications** and **UI Components**.

### 5.1 Application Questions

These feel similar to general system design interviews, but focus on the **client side**: application architecture and client-side implementation details.

Modern web apps are interactive and rich applications that can do virtually what desktop applications can (Gmail, Facebook, YouTube, ChatGPT, Google Calendar). They are dynamic — page navigations usually don't require a full page refresh; the app uses JavaScript to fetch remote data and dynamically change the contents and URL (SPA behavior).

Common architectures: **MVC**, **MVVM**, **Flux/Redux** (unidirectional). React is one of the most popular libraries for building interactive web apps and many React apps adopt a Flux/Redux-based architecture.

> **Important**: Different applications have their own **unique aspects and talking points**. Focus on the parts that are unique to the application — don't spend too much time on general stuff applicable to all questions.

**Key approach**: Design high-level architecture → identify components and APIs → dive deep into areas that are **interesting/unique** to the problem.

#### Common Application Questions

| Application | Examples | Important Areas |
|-------------|----------|-----------------|
| **News Feed** | Facebook, Twitter | Feed interactions, pagination approaches, post composer |
| **Messaging / Chat** | Messenger, Slack, Discord | Real-time chat, message syncing, message list, chat list |
| **E-commerce** | Amazon, eBay | Product listing, product detail, cart, checkout |
| **Photo Sharing** | Instagram, Flickr, Google Photos | Photo browsing, editing, uploading |
| **Travel Booking** | Airbnb, Skyscanner | Search UI, search results, booking UI |
| **Video Streaming** | Netflix, YouTube | Video player, video streaming, recommended videos |
| **Pinterest** | Pinterest | Masonry layout, media feed optimizations |
| **Collaborative Apps** | Google Docs, Notion | Real-time collaboration protocols, conflict resolution, state syncing |
| **Email Client** | Outlook, Gmail | Mailbox syncing, mailbox UI, email composer |
| **Drawing Apps** | Figma, Excalidraw, Canva | Rendering approach, client state/data model, state management |
| **Maps** | Google/Apple Maps | Map rendering, displaying locations |
| **File Storage** | Google Drive, Dropbox | File uploading, downloading, file explorer |
| **Video Conferencing** | Zoom, Google Meet | Video streaming, various viewing modes |
| **Ridesharing** | Uber, Lyft | Trip booking, driver location, app states |
| **Music Streaming** | Spotify, Apple Music | Audio streaming, music player UI, playlists UI |
| **Games** | Tetris, Snake | Game state, game loop, game logic |

### 5.2 UI Component Questions

In modern front end development, it is common to use component libraries: jQuery UI, Bootstrap, Material UI, Chakra UI, etc. Building UI components is a core expectation of Front End Engineers. Interview questions focus on **complex** components (autocomplete, dropdown, modal) — not trivial ones like text/button/badge.

**Key approach**: 
1. Determine subcomponents
2. Define external-facing API (props/options)
3. Describe internal component state
4. Define API between subcomponents
5. Dive into optimizations: performance, accessibility, UX, security

You may need to write a small amount of code to:
- Explain non-trivial logic
- Describe shape of component state
- Describe component hierarchy

#### Example: Image Carousel Component API

```jsx
<ImageCarousel
  images={...}
  onPrev={...}
  onNext={...}
  layout="horizontal"
>
  <ImageCarouselImage style={...} />
  <ImageThumbnail onClick={...} />
</ImageCarousel>
```

#### Theming Customization
You will almost certainly be expected to design a way for developers to customize the component appearance (CSS variables, className props, theme providers, etc.). Refer to [UI Components API Design Principles](https://www.greatfrontend.com/front-end-interview-guidebook/user-interface-components-api-design-principles) for an overview and comparison of different approaches.

#### Common UI Component Questions

- Multiselect component
- Datepicker
- Data table with sorting and pagination
- Rich text editor
- Modal component
- Image carousel
- Embeddable poll widget
- Dropdown menu component
- Autocomplete component

---

## 6. Quick Reference: RADIO Cheat Sheet

```
┌─────────────────────────────────────────────────────────┐
│                    RADIO FRAMEWORK                       │
├──────────┬──────────────────────────────────────────────┤
│ R (15%)  │ Requirements: Ask clarifying questions       │
│          │ → Use cases, functional/non-functional reqs  │
│          │ → Core features vs nice-to-have              │
│          │ → Devices, users, offline support             │
├──────────┼──────────────────────────────────────────────┤
│ A (20%)  │ Architecture: Draw component diagram          │
│          │ → Model/Store, View, Controller, Server       │
│          │ → Data flow arrows between components         │
│          │ → Describe each component's responsibility    │
├──────────┼──────────────────────────────────────────────┤
│ D (10%)  │ Data Model: List entities and fields          │
│          │ → Server data vs client-only data             │
│          │ → Ephemeral state vs persisted state          │
│          │ → Map fields to owning components             │
├──────────┼──────────────────────────────────────────────┤
│ I (15%)  │ Interface: Define APIs                        │
│          │ → Server-client (HTTP endpoints)              │
│          │ → Client-client (JS functions)                │
│          │ → Parameters and response shapes              │
├──────────┼──────────────────────────────────────────────┤
│ O (40%)  │ Optimizations: Deep dive into key areas       │
│          │ → Performance, a11y, networking, UX           │
│          │ → Security, i18n, multi-device                │
│          │ → Focus on YOUR strengths + product's needs   │
└──────────┴──────────────────────────────────────────────┘
```

---

## Cross-References

| Topic | Related Notes | Connection |
|-------|---------------|------------|
| Back-end system design comparison | [ByteByteGo System Design](./bytebytego-system-design.md) | RADIO focuses on client-side; ByteByteGo focuses on distributed systems |
| System design interview framework | [System Design Interview Vol.1](./system-design-interview-vol1.md) | RADIO's R step parallels the "Understand the Problem" step; both emphasize structured approaches |
| API design (REST, GraphQL) | [ByteByteGo System Design](./bytebytego-system-design.md#1-communication-protocols) | RADIO's Interface section uses HTTP APIs; ByteByteGo covers REST best practices in depth |
| RADIO applied: News Feed | [News Feed (Facebook)](./greatfrontend-news-feed-facebook.md) | Cursor pagination, virtualized lists, optimistic updates, SSR+CSR hybrid |
| RADIO applied: Pinterest | [Pinterest](./greatfrontend-pinterest.md) | Masonry layout, absolute positioning, paint scheduling, responsive images |

---

## References

- [GreatFrontEnd Front End System Design Playbook](https://www.greatfrontend.com/front-end-system-design-playbook/introduction)
- [RADIO Framework](https://www.greatfrontend.com/system-design/framework)
- [Common Mistakes](https://www.greatfrontend.com/system-design/common-mistakes)
- [Evaluation Criteria](https://www.greatfrontend.com/system-design/evaluation-axes)
- [Types of Questions](https://www.greatfrontend.com/front-end-system-design-playbook/types-of-questions)
- [Excalidraw](https://excalidraw.com/) — Free drawing tool for architecture diagrams
- [diagrams.net](https://app.diagrams.net/) — Free drawing tool for architecture diagrams
