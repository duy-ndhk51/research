# ByteByteGo — System Design Visual Reference

> **Author**: Alex Xu (ByteByteGo)  
> **Year**: 2022  
> **Pages**: 159  
> **Format**: Visual infographic compilation  
> **Source PDF**: [bytebytego-system-design.pdf](../sources/books/bytebytego-system-design.pdf)

---

## TL;DR

A comprehensive visual reference covering the breadth of system design topics through infographic-style diagrams. Covers communication protocols, API design, architecture patterns, databases, caching, scaling strategies, DevOps, security, Linux internals, and real-world system design case studies. Ideal as a **quick-reference companion** to deeper reading on system design interviews and distributed systems.

---

## Topics Covered

### 1. Communication Protocols

#### HTTP Versions

| Version | Key Feature | Connection |
|---------|------------|------------|
| **HTTP/1.0** | One request per connection | New TCP connection each time |
| **HTTP/1.1** | Persistent connections, pipelining | Keep-alive by default |
| **HTTP/2** | Multiplexing, header compression, server push | Single TCP connection, binary framing |
| **HTTP/3** | QUIC (UDP-based), zero RTT handshakes | No head-of-line blocking |

#### HTTPS Handshake (TLS)

```
Client                          Server
  |--- ClientHello (ciphers) ---->|
  |<-- ServerHello + Certificate -|
  |--- Key Exchange ------------->|
  |<-- [Encrypted] Session -------|
  |<======= Encrypted Data ======>|
```

1. Client sends supported cipher suites
2. Server responds with chosen cipher + certificate
3. Client verifies certificate, generates session key
4. Both sides encrypt all subsequent traffic

#### API Architecture Styles

| Style | Protocol | Format | Use Case |
|-------|----------|--------|----------|
| **REST** | HTTP | JSON/XML | CRUD operations, web APIs |
| **GraphQL** | HTTP | JSON | Flexible queries, mobile apps with bandwidth constraints |
| **gRPC** | HTTP/2 | Protocol Buffers | Microservice-to-microservice, low latency |
| **WebSocket** | TCP | Binary/Text | Real-time bidirectional (chat, live feeds) |
| **SOAP** | HTTP/SMTP | XML | Enterprise, ACID transactions |
| **Webhook** | HTTP (callback) | JSON | Event-driven notifications |

#### REST API Best Practices

- Use **nouns** for resources: `/users`, `/orders` (not `/getUsers`)
- HTTP methods convey actions: `GET` (read), `POST` (create), `PUT` (full update), `PATCH` (partial update), `DELETE`
- Use **plural nouns**: `/users/123` not `/user/123`
- Versioning: `/api/v1/users`
- Pagination: `?page=2&limit=20`
- Filtering: `?status=active&sort=created_at`
- Return proper HTTP status codes:

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET/PUT/PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Validation error |
| 401 | Unauthorized | Missing/invalid auth |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 429 | Too Many Requests | Rate limited |
| 500 | Internal Server Error | Server fault |

#### GraphQL vs REST

| Aspect | REST | GraphQL |
|--------|------|---------|
| Endpoints | Multiple (`/users`, `/posts`) | Single (`/graphql`) |
| Data fetching | Fixed structure per endpoint | Client specifies exact fields |
| Over-fetching | Common | Eliminated |
| Under-fetching | Requires multiple round trips | Single query for nested data |
| Caching | HTTP caching (simple) | More complex (query-based) |
| Learning curve | Low | Higher |

### 2. Architecture Patterns

#### Monolith vs Microservices

```
Monolith                     Microservices
┌─────────────────┐         ┌────────┐ ┌────────┐ ┌────────┐
│   UI + Business │         │ User   │ │ Order  │ │ Payment│
│   Logic + Data  │         │ Service│ │ Service│ │ Service│
│   (Single Unit) │         └───┬────┘ └───┬────┘ └───┬────┘
└─────────────────┘             │          │          │
                            ┌───┴──────────┴──────────┴───┐
                            │       Message Bus / API GW   │
                            └──────────────────────────────┘
```

| Aspect | Monolith | Microservices |
|--------|----------|---------------|
| Deployment | Single unit | Independent per service |
| Scaling | Scale entire app | Scale individual services |
| Tech stack | Uniform | Polyglot (different per service) |
| Failure | Single failure can crash all | Isolated failures |
| Complexity | Simple initially | Distributed systems complexity |
| Data | Shared database | Database per service |
| Team | Single team can manage | Aligned to business domains |

#### Microservices Communication

| Pattern | Type | When to Use |
|---------|------|-------------|
| **Synchronous (REST/gRPC)** | Request-response | Real-time queries, simple flows |
| **Asynchronous (Message Queue)** | Event-driven | Decoupled processing, eventual consistency |
| **Event Sourcing** | Append-only log | Audit trails, complex domain events |
| **Saga Pattern** | Choreography/Orchestration | Distributed transactions across services |

#### 18 Key Design Patterns

| Category | Pattern | Purpose |
|----------|---------|---------|
| **Creational** | Singleton | One instance globally |
| | Factory Method | Create objects without specifying exact class |
| | Abstract Factory | Create families of related objects |
| | Builder | Construct complex objects step by step |
| | Prototype | Clone existing objects |
| **Structural** | Adapter | Incompatible interface compatibility |
| | Bridge | Separate abstraction from implementation |
| | Composite | Tree structures of objects |
| | Decorator | Add behavior dynamically |
| | Facade | Simplified interface to complex subsystem |
| | Proxy | Placeholder for another object |
| **Behavioral** | Observer | Notify dependents of state changes |
| | Strategy | Interchangeable algorithms |
| | Command | Encapsulate requests as objects |
| | Iterator | Sequential access to elements |
| | State | Behavior changes with state |
| | Template Method | Define skeleton, let subclasses fill steps |
| | Chain of Responsibility | Pass request along handler chain |

### 3. Databases

#### SQL vs NoSQL

| Feature | SQL (Relational) | NoSQL |
|---------|------------------|-------|
| Schema | Fixed, predefined | Flexible, dynamic |
| Scaling | Vertical (scale up) | Horizontal (scale out) |
| Transactions | ACID guarantees | BASE (eventual consistency) |
| Query | SQL (standardized) | Varies by type |
| Best for | Complex queries, joins, consistency | High throughput, flexible schema, scale |

#### NoSQL Database Types

| Type | Examples | Data Model | Use Case |
|------|----------|------------|----------|
| **Key-Value** | Redis, DynamoDB, Memcached | Key → Value | Caching, sessions, shopping carts |
| **Document** | MongoDB, CouchDB, Firestore | Key → JSON document | Content management, catalogs, user profiles |
| **Column-Family** | Cassandra, HBase, BigTable | Row key → Column families | Time-series, IoT, analytics at scale |
| **Graph** | Neo4j, Amazon Neptune, ArangoDB | Nodes + Edges | Social networks, fraud detection, recommendations |

#### How to Choose the Right Database

```
Need ACID transactions?
├── Yes → Relational (PostgreSQL, MySQL)
└── No
    ├── Need fast key lookups?
    │   └── Yes → Key-Value (Redis, DynamoDB)
    ├── Need flexible documents?
    │   └── Yes → Document (MongoDB)
    ├── Need to store relationships?
    │   └── Yes → Graph (Neo4j)
    ├── Need time-series data?
    │   └── Yes → Column-Family (Cassandra) or Time-series DB (InfluxDB)
    └── Need full-text search?
        └── Yes → Search engine (Elasticsearch)
```

#### CAP Theorem

Every distributed data store can only guarantee **two of three** properties:

| Property | Meaning |
|----------|---------|
| **Consistency** | Every read returns the most recent write |
| **Availability** | Every request gets a non-error response |
| **Partition Tolerance** | System continues despite network partitions |

```
        C (Consistency)
       / \
      /   \
    CP     CA  ← (CA not practical in distributed systems)
    /       \
   P ─────── A
     (PA = AP)
```

| Choice | Sacrifice | Examples |
|--------|-----------|----------|
| **CP** | Availability | MongoDB, HBase, Redis |
| **AP** | Consistency | Cassandra, DynamoDB, CouchDB |
| **CA** | Partition Tolerance | Single-node RDBMS (not truly distributed) |

**In practice**: Network partitions are inevitable, so the real choice is between **CP** and **AP**.

#### Database Scaling Strategies

| Strategy | How It Works | Trade-off |
|----------|-------------|-----------|
| **Vertical Scaling** | Bigger machine (more CPU/RAM) | Hardware limits, single point of failure |
| **Read Replicas** | Copy data to read-only replicas | Replication lag, eventual consistency |
| **Sharding** | Distribute data across multiple databases | Cross-shard queries are complex |
| **Denormalization** | Duplicate data to avoid joins | Data inconsistency risk, storage cost |

**Sharding strategies**:
- **Range-based**: Shard by value ranges (e.g., user IDs 1–1M, 1M–2M)
- **Hash-based**: Hash the shard key → consistent distribution
- **Directory-based**: Lookup table maps data → shard

### 4. Caching

#### Caching Strategies

| Strategy | Description | Consistency | Performance |
|----------|-------------|-------------|-------------|
| **Cache-Aside (Lazy)** | App reads cache first; on miss, reads DB, writes to cache | App manages | Read-heavy workloads |
| **Read-Through** | Cache sits between app and DB; auto-loads on miss | Cache manages | Simpler app code |
| **Write-Through** | Writes go to cache AND DB synchronously | Strong | Higher write latency |
| **Write-Behind (Write-Back)** | Writes to cache; async flush to DB | Eventual | Lower write latency, risk of data loss |
| **Write-Around** | Writes go directly to DB; cache loads on read miss | Eventually consistent | Avoids cache pollution |

```
Cache-Aside Pattern:
┌──────┐    1. Read    ┌───────┐
│ App  │──────────────>│ Cache │
│      │<──────────────│       │
│      │  2a. Hit      └───────┘
│      │
│      │  2b. Miss     ┌──────┐
│      │──────────────>│  DB  │
│      │<──────────────│      │
│      │  3. Return    └──────┘
│      │
│      │  4. Write     ┌───────┐
│      │──────────────>│ Cache │
└──────┘               └───────┘
```

#### Cache Eviction Policies

| Policy | Description | Use Case |
|--------|-------------|----------|
| **LRU** (Least Recently Used) | Evict least recently accessed | General purpose |
| **LFU** (Least Frequently Used) | Evict least accessed overall | Frequency-based |
| **FIFO** | First in, first out | Simple, time-based |
| **TTL** | Expire after time-to-live | Data with known staleness window |

#### Redis Key Concepts

- **In-memory** data store → sub-millisecond latency
- Data structures: Strings, Lists, Sets, Sorted Sets, Hashes, Streams, HyperLogLog
- **Persistence**: RDB (snapshots) and AOF (append-only file)
- **Replication**: Master-replica for high availability
- **Cluster**: Auto-sharding across multiple nodes
- **Pub/Sub**: Real-time messaging
- Common uses: Caching, session store, rate limiter, leaderboard, message broker

### 5. Scaling & Infrastructure

#### How to Scale to Millions of Users

Progression from single server to massive scale:

```
Step 1: Single server (Web + DB)
  ↓
Step 2: Separate DB server
  ↓
Step 3: Add load balancer + multiple web servers
  ↓
Step 4: Database replication (master + read replicas)
  ↓
Step 5: Add cache layer (Redis/Memcached)
  ↓
Step 6: CDN for static assets
  ↓
Step 7: Stateless web tier (store sessions externally)
  ↓
Step 8: Database sharding
  ↓
Step 9: Split into microservices
  ↓
Step 10: Message queues for async processing
```

#### Load Balancing Algorithms

| Algorithm | How It Works | Best For |
|-----------|-------------|----------|
| **Round Robin** | Rotate through servers sequentially | Equal-capacity servers |
| **Weighted Round Robin** | Assign weights proportional to capacity | Heterogeneous servers |
| **Least Connections** | Route to server with fewest active connections | Variable request durations |
| **Least Response Time** | Route to fastest responding server | Latency-sensitive apps |
| **IP Hash** | Hash client IP → consistent server | Session affinity |
| **Random** | Randomly pick a server | Simple, stateless |

| Layer | Scope | Examples |
|-------|-------|---------|
| **L4 (Transport)** | Routes by IP/port, no payload inspection | HAProxy, AWS NLB |
| **L7 (Application)** | Routes by HTTP headers, URL path, cookies | Nginx, AWS ALB, Envoy |

#### CDN (Content Delivery Network)

```
User in Tokyo → Edge Server (Tokyo) → Cache HIT → Content
                                    → Cache MISS → Origin Server (US) → Cache + Content
```

- **Push CDN**: Origin pushes content proactively
- **Pull CDN**: Edge server pulls on first request, then caches

| CDN Use Case | Example |
|-------------|---------|
| Static assets | Images, CSS, JS, videos |
| API acceleration | Cache GET responses at edge |
| Live streaming | Stream from nearest edge |
| Security | DDoS protection, WAF at edge |

#### Proxy vs Reverse Proxy

| Type | Position | Purpose |
|------|----------|---------|
| **Forward Proxy** | Between client and internet | Anonymity, content filtering, caching for clients |
| **Reverse Proxy** | Between internet and servers | Load balancing, SSL termination, caching for servers |

#### Rate Limiting Algorithms

| Algorithm | How It Works | Pros | Cons |
|-----------|-------------|------|------|
| **Token Bucket** | Tokens refill at fixed rate; each request costs a token | Allows bursts, smooth | Memory per user |
| **Leaky Bucket** | Requests enter bucket; processed at fixed rate | Smooth output | No burst handling |
| **Fixed Window** | Count requests in fixed time windows | Simple | Burst at window edges |
| **Sliding Window Log** | Track each request timestamp | Accurate | Memory-intensive |
| **Sliding Window Counter** | Weighted average of current + previous window | Balanced accuracy | Approximation |

#### Consistent Hashing

Distributes data across nodes on a **hash ring**. When a node is added/removed, only `K/N` keys need redistribution (K = keys, N = nodes) instead of rehashing everything.

```
        Node A
       /      \
  Key 1        Node B
      |        /
   Hash Ring
      |      \
  Key 2    Node C
       \    /
        Key 3
```

- Used by: DynamoDB, Cassandra, Akamai CDN, Discord
- **Virtual nodes**: Each physical node maps to multiple points on the ring for better distribution

### 6. Message Queues & Async Processing

| Component | Purpose |
|-----------|---------|
| **Producer** | Publishes messages to the queue |
| **Queue/Topic** | Stores messages until consumed |
| **Consumer** | Reads and processes messages |
| **Dead Letter Queue** | Stores messages that failed processing |

#### Kafka vs RabbitMQ vs SQS

| Feature | Kafka | RabbitMQ | SQS |
|---------|-------|----------|-----|
| Model | Distributed log | Message broker | Managed queue |
| Ordering | Per-partition ordering | Per-queue FIFO | FIFO (optional) |
| Throughput | Very high (millions/sec) | Moderate | High |
| Replay | Yes (retention-based) | No (once consumed) | No |
| Use case | Event streaming, logs | Task queues, routing | Serverless, AWS-native |
| Complexity | High (ops overhead) | Moderate | Low (fully managed) |

### 7. Security & Authentication

#### Session vs Token Authentication

| Aspect | Session-based | Token-based (JWT) |
|--------|--------------|-------------------|
| State | Server stores session | Stateless (token contains data) |
| Storage | Server-side session store | Client-side (localStorage/cookie) |
| Scalability | Requires shared session store | No server state needed |
| Revocation | Easy (delete session) | Hard (need blocklist or short TTL) |

#### JWT (JSON Web Token)

```
Header.Payload.Signature

Header:  { "alg": "HS256", "typ": "JWT" }
Payload: { "sub": "user123", "name": "Alice", "exp": 1700000000 }
Signature: HMACSHA256(base64(header) + "." + base64(payload), secret)
```

- **Compact**: Fits in HTTP headers
- **Self-contained**: Payload carries user info (no DB lookup)
- **Tamper-proof**: Signature verifies integrity
- **Stateless**: Server doesn't store sessions

#### OAuth 2.0 Flow

```
User → App → Authorization Server (Google, GitHub, etc.)
                    ↓
        User grants permission
                    ↓
        Auth Server returns Authorization Code
                    ↓
App exchanges Code for Access Token (server-to-server)
                    ↓
App uses Access Token to access Resource Server (API)
```

#### SSO (Single Sign-On)

One login gives access to multiple applications. Uses protocols like SAML, OpenID Connect (OIDC), or OAuth 2.0.

#### How to Store Passwords Safely

```
1. NEVER store plaintext passwords
2. Use slow hashing: bcrypt, scrypt, or Argon2 (NOT MD5/SHA)
3. Add unique salt per password
4. Consider pepper (application-level secret)
```

### 8. DevOps & Infrastructure

#### CI/CD Pipeline

```
Code → Build → Test → Deploy (Staging) → Deploy (Production)
  ↑       ↑       ↑          ↑                    ↑
  Git   Compile  Unit +    Integration         Canary /
 Push   + Lint  Integration   Test           Blue-Green
```

| Stage | Tools |
|-------|-------|
| Source Control | Git, GitHub, GitLab |
| Build | Maven, Gradle, webpack, Docker |
| Test | JUnit, Jest, Selenium, k6 |
| Deploy | Jenkins, GitHub Actions, ArgoCD, Spinnaker |
| Monitor | Prometheus, Grafana, Datadog, PagerDuty |

#### Docker vs Kubernetes

| Feature | Docker | Kubernetes |
|---------|--------|------------|
| What | Container runtime | Container orchestration |
| Scope | Single host | Multi-host cluster |
| Scaling | Manual | Auto-scaling |
| Networking | Bridge/overlay | Service mesh, ingress |
| Use | Package + run apps | Manage + scale containers |

**Docker concepts**: Image → Container → Registry → Dockerfile → Compose
**Kubernetes concepts**: Pod → Service → Deployment → Ingress → Namespace → ConfigMap/Secret

#### Cloud Service Models

| Model | You Manage | Provider Manages | Example |
|-------|-----------|------------------|---------|
| **IaaS** | OS, runtime, app, data | Hardware, networking, virtualization | AWS EC2, GCP Compute |
| **PaaS** | App, data | Everything else | Heroku, AWS Elastic Beanstalk, Google App Engine |
| **SaaS** | Nothing (just use it) | Everything | Gmail, Slack, Salesforce |

### 9. Networking Fundamentals

#### What Happens When You Type a URL in the Browser?

```
1. Browser checks cache (browser → OS → router → ISP)
2. DNS resolution → IP address
3. TCP handshake (SYN → SYN-ACK → ACK)
4. TLS handshake (if HTTPS)
5. HTTP request sent
6. Server processes request
7. Server sends HTTP response
8. Browser parses HTML
9. Browser fetches sub-resources (CSS, JS, images)
10. Page renders (DOM → CSSOM → Render Tree → Layout → Paint)
```

#### TCP vs UDP

| Feature | TCP | UDP |
|---------|-----|-----|
| Connection | Connection-oriented (3-way handshake) | Connectionless |
| Reliability | Guaranteed delivery, ordered | Best-effort, no order |
| Speed | Slower (overhead) | Faster (no overhead) |
| Use case | HTTP, email, file transfer | Video streaming, DNS, gaming |

#### OSI Model (7 Layers)

| Layer | Name | Protocol/Example | Data Unit |
|-------|------|------------------|-----------|
| 7 | Application | HTTP, FTP, SMTP, DNS | Data |
| 6 | Presentation | SSL/TLS, JPEG, ASCII | Data |
| 5 | Session | NetBIOS, RPC | Data |
| 4 | Transport | TCP, UDP | Segment |
| 3 | Network | IP, ICMP, OSPF | Packet |
| 2 | Data Link | Ethernet, Wi-Fi | Frame |
| 1 | Physical | Cables, radio waves | Bit |

### 10. Linux Essentials

#### Most-Used Linux Commands

| Command | Purpose |
|---------|---------|
| `ls` | List directory contents |
| `cd` | Change directory |
| `grep` | Search text patterns |
| `find` | Find files by name/attributes |
| `ps` / `top` / `htop` | Process monitoring |
| `chmod` / `chown` | File permissions |
| `curl` / `wget` | HTTP requests / download |
| `tar` / `gzip` | Archive / compress |
| `ssh` | Remote login |
| `awk` / `sed` | Text processing |
| `df` / `du` | Disk usage |
| `netstat` / `ss` | Network connections |
| `systemctl` | Service management |
| `journalctl` | System logs |
| `crontab` | Scheduled tasks |

#### Linux File System

```
/
├── bin/      → Essential binaries (ls, cp, mv)
├── etc/      → Configuration files
├── home/     → User home directories
├── var/      → Variable data (logs, caches)
├── tmp/      → Temporary files
├── usr/      → User programs and libraries
├── opt/      → Optional/third-party software
├── dev/      → Device files
├── proc/     → Process information (virtual)
└── sys/      → System information (virtual)
```

### 11. Latency Numbers Every Programmer Should Know

| Operation | Latency | Notes |
|-----------|---------|-------|
| L1 cache reference | ~1 ns | |
| L2 cache reference | ~4 ns | 4x L1 |
| Main memory (RAM) | ~100 ns | 100x L1 |
| SSD random read | ~16 μs | 16,000x L1 |
| HDD seek | ~2 ms | 2,000,000x L1 |
| Send 1KB over 1 Gbps network | ~10 μs | |
| Read 1MB sequentially from memory | ~3 μs | |
| Read 1MB sequentially from SSD | ~49 μs | |
| Read 1MB sequentially from HDD | ~825 μs | |
| Round trip within same datacenter | ~500 μs | |
| Round trip CA → Netherlands → CA | ~150 ms | |

**Key insight**: Disk is ~100,000x slower than memory. Network round trips dominate latency in distributed systems. **Cache aggressively**.

### 12. System Design Case Studies — Key Patterns

#### URL Shortener (e.g., bit.ly)

- **Write**: Generate unique short ID (Base62 encoding or hash), store mapping in DB
- **Read**: Look up short ID → redirect to original URL
- **Scale**: Cache popular URLs (hot data), use hash-based sharding on short ID
- **Components**: API servers + Cache (Redis) + Database (NoSQL for fast reads)

#### Chat System (e.g., WhatsApp)

- **Real-time**: WebSocket connections for persistent bidirectional communication
- **Offline**: Store messages in queue; deliver when recipient reconnects
- **Group chat**: Fan-out on write (small groups) or fan-out on read (large groups)
- **Components**: WebSocket servers + Message queue (Kafka) + DB (Cassandra for messages) + Push notification service

#### News Feed (e.g., Twitter/Facebook)

| Approach | How | Trade-off |
|----------|-----|-----------|
| **Fan-out on write** | Pre-compute feed for all followers on post | Fast read, slow write, memory-heavy |
| **Fan-out on read** | Compute feed at read time | Slow read, efficient write |
| **Hybrid** | Fan-out on write for normal users; fan-out on read for celebrities | Balanced |

#### Video Streaming (e.g., YouTube)

- **Upload**: Encode video into multiple resolutions + formats (adaptive bitrate)
- **Storage**: Object storage (S3) + CDN for delivery
- **Streaming**: Use CDN edge servers; adaptive bitrate streaming (HLS/DASH)
- **Metadata**: Separate DB for video info, comments, likes

#### Distributed Key-Value Store (e.g., DynamoDB)

- **Consistent hashing** for data partitioning
- **Replication** across N nodes for fault tolerance
- **Vector clocks** for conflict resolution
- **Quorum consensus**: W + R > N for strong consistency
  - W = nodes that must acknowledge writes
  - R = nodes that must respond to reads
  - N = total replicas

#### Rate Limiter

- **Token bucket** or **sliding window** algorithm
- Store counts in **Redis** (fast, atomic operations)
- Return `HTTP 429 Too Many Requests` when limit exceeded
- Consider: per-user, per-IP, per-API-key limits
- Place at **API Gateway** level for centralized enforcement

#### Web Crawler

```
Seed URLs → URL Frontier (Queue)
    ↓
Fetcher (HTTP requests)
    ↓
Parser (extract links + content)
    ↓
URL Filter (dedup, robots.txt check)
    ↓
Content Storage (S3 / HDFS)
```

- **Politeness**: Respect `robots.txt`, rate-limit per domain
- **Deduplication**: URL dedup (hash set) + content dedup (fingerprinting)
- **Priority**: Prioritize high-value pages
- **Trap avoidance**: Detect infinite URL patterns

### 13. Git Essentials

#### Git Workflow

```
Working Dir → (git add) → Staging → (git commit) → Local Repo → (git push) → Remote
                                                       ↑
                                          (git pull) ──┘
```

#### Common Git Commands

| Command | Purpose |
|---------|---------|
| `git clone` | Copy remote repo |
| `git branch` | Create/list branches |
| `git checkout -b` | Create and switch to branch |
| `git merge` | Merge branch into current |
| `git rebase` | Replay commits on new base |
| `git stash` | Save uncommitted changes |
| `git cherry-pick` | Apply specific commit |
| `git reset` | Undo commits (soft/mixed/hard) |
| `git reflog` | Recovery — find lost commits |

#### Merge vs Rebase

| Aspect | Merge | Rebase |
|--------|-------|--------|
| History | Preserves all commits + merge commit | Linear history |
| Safety | Never rewrites history | Rewrites commit hashes |
| Use when | Merging feature → main | Updating feature with latest main |
| Rule | Safe for shared branches | **Never rebase shared/public branches** |

---

## System Design Interview Framework

### 4-Step Approach

| Step | Duration | Activities |
|------|----------|------------|
| **1. Understand the problem** | 3–5 min | Clarify requirements, scope, constraints, scale (DAU, QPS) |
| **2. High-level design** | 10–15 min | Draw major components, APIs, data flow |
| **3. Deep dive** | 10–15 min | Detail 2–3 critical components (the interviewer cares about) |
| **4. Wrap up** | 3–5 min | Bottlenecks, failure modes, monitoring, future improvements |

### Back-of-the-Envelope Estimation

| Metric | Quick Math |
|--------|-----------|
| QPS | DAU × avg requests per user / 86,400 |
| Peak QPS | QPS × 2–5 |
| Storage per day | Avg object size × writes per day |
| Bandwidth | QPS × avg response size |
| 1 day | ~100K seconds |
| 1 year | ~30M seconds |

| Power of 2 | Value | Approx |
|------------|-------|--------|
| 2^10 | 1,024 | ~1 Thousand (1 KB) |
| 2^20 | 1,048,576 | ~1 Million (1 MB) |
| 2^30 | ~1 Billion | ~1 GB |
| 2^40 | ~1 Trillion | ~1 TB |

---

## Common Pitfalls

| Pitfall | Why It Hurts | Fix |
|---------|-------------|-----|
| Jumping into design without requirements | Miss constraints, over/under-design | Spend 3–5 min clarifying scope, DAU, QPS |
| Single point of failure | Any failure takes down the whole system | Add redundancy at every layer |
| No caching strategy | Unnecessary DB load, high latency | Cache frequently-read, rarely-changed data |
| Ignoring network partitions | System hangs or loses data | Design for CAP trade-offs; use retries, circuit breakers |
| Synchronous everything | One slow service blocks entire chain | Use async messaging for non-critical paths |
| Storing everything in one DB | Scaling bottleneck | Shard, replicate, use polyglot persistence |
| No rate limiting | DDoS/abuse takes down the system | Rate limit at API Gateway |
| Ignoring failure modes | "What if X fails?" is a top interview question | Design for graceful degradation |

---

## Cross-References

| Topic in This Book | Related Notes | Connection |
|--------------------|---------------|------------|
| Caching strategies | [Cracking the Coding Interview](../10-soft-skills/interviewing/cracking-the-coding-interview.md) | System Design chapter covers scalability |
| Design patterns | [Learning Patterns](../04-frontend/react/learning-patterns.md) | Frontend-specific patterns (Provider, Observer, etc.) |
| API design, REST, GraphQL | [Learning React](../04-frontend/react/learning-react.md) | Data fetching with fetch, GraphQL chapter |
| Clean code in system design | [Clean Code](../01-fundamentals/clean-code/clean-code.md) | Naming, modularity, separation of concerns |

---

## References

- [Source PDF](../sources/books/bytebytego-system-design.pdf)
- [ByteByteGo Website](https://bytebytego.com) — Alex Xu's system design platform
- [System Design Interview Vol. 1](https://www.amazon.com/System-Design-Interview-insiders-Second/dp/B08CMF2CQF) — Deep dive companion book
- [System Design Interview Vol. 2](https://www.amazon.com/System-Design-Interview-Insiders-Guide/dp/1736049119) — Advanced topics
- [System Design Primer (GitHub)](https://github.com/donnemartin/system-design-primer) — Open-source system design study guide
