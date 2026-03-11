# 02 - System Design

System design, software architecture, and distributed systems.

## Topics

| Topic | Folder | Status |
|-------|--------|--------|
| High-Level Design | [high-level-design/](./high-level-design/) | 📝 In progress |
| Low-Level Design | [low-level-design/](./low-level-design/) | 🔲 Not started |
| Scalability | [scalability/](./scalability/) | 🔲 Not started |
| Microservices | [microservices/](./microservices/) | 🔲 Not started |
| Event-Driven Architecture | [event-driven/](./event-driven/) | 🔲 Not started |
| Caching | [caching/](./caching/) | 🔲 Not started |
| Databases (system design) | [databases/](./databases/) | 🔲 Not started |
| Message Queues | [message-queues/](./message-queues/) | 🔲 Not started |
| Case Studies | [case-studies/](./case-studies/) | 🔲 Not started |

## Source Books

| Book | Author | Notes | Key Topics |
|------|--------|-------|------------|
| ByteByteGo System Design | Alex Xu | [Notes](./bytebytego-system-design.md) | Communication protocols (REST, GraphQL, gRPC, WebSocket), architecture patterns (monolith, microservices), databases (SQL vs NoSQL, CAP theorem, sharding), caching (Redis, strategies), scaling (load balancing, CDN, consistent hashing), message queues (Kafka, RabbitMQ), security (JWT, OAuth, SSO), DevOps (CI/CD, Docker, K8s), system design case studies |
| System Design Interview Vol. 1 (2nd Ed.) | Alex Xu | [Notes](./system-design-interview-vol1.md) | 4-step interview framework, scaling to millions, back-of-the-envelope estimation, rate limiter, consistent hashing, key-value store, unique ID generator (Snowflake), URL shortener, web crawler, notification system, news feed (fan-out), chat system (WebSocket), search autocomplete (trie), YouTube (video transcoding), Google Drive (block sync) |

## Key Concepts to Master

- CAP Theorem, PACELC
- Load balancing strategies
- Database sharding & replication
- Consistent hashing
- Rate limiting & throttling
- CDN, reverse proxy
- Leader election, consensus algorithms
