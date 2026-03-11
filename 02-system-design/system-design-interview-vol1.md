# System Design Interview — An Insider's Guide (Volume 1)

> **Author**: Alex Xu  
> **Year**: 2020 (2nd Edition)  
> **Pages**: 269  
> **Publisher**: Independently published  
> **Source PDF**: [system-design-interview-an-insiders-guide-2nbsped-9798664653403-volume-1.pdf](../sources/books/system-design-interview-an-insiders-guide-2nbsped-9798664653403-volume-1.pdf)

---

## TL;DR

A hands-on, interview-focused guide to system design. Chapters 1–3 build foundational knowledge (scaling strategies, back-of-the-envelope estimation, and a 4-step interview framework). Chapters 4–15 each walk through a **complete system design problem** from requirements → high-level design → deep dive → wrap-up. Every chapter follows the same structured approach, making it an excellent drill book for system design interviews.

---

## Book Structure

| Chapter | Topic | Category |
|---------|-------|----------|
| 1 | Scale From Zero to Millions of Users | Foundation |
| 2 | Back-of-the-Envelope Estimation | Foundation |
| 3 | A Framework for System Design Interviews | Framework |
| 4 | Design a Rate Limiter | Infrastructure |
| 5 | Design Consistent Hashing | Infrastructure |
| 6 | Design a Key-Value Store | Infrastructure |
| 7 | Design a Unique ID Generator | Infrastructure |
| 8 | Design a URL Shortener | Application |
| 9 | Design a Web Crawler | Application |
| 10 | Design a Notification System | Application |
| 11 | Design a News Feed System | Application |
| 12 | Design a Chat System | Application |
| 13 | Design a Search Autocomplete System | Application |
| 14 | Design YouTube | Application |
| 15 | Design Google Drive | Application |
| 16 | The Learning Continues | Guidance |

---

## Part I: Foundations (Ch 1–3)

### Ch 1 — Scale From Zero to Millions of Users

A progressive scaling journey — each step solves a bottleneck introduced by the previous:

```
Single Server
  ↓  Separate DB
  ↓  Load Balancer + Multiple Web Servers
  ↓  Database Replication (master/slave)
  ↓  Cache Layer (Memcached/Redis)
  ↓  CDN for Static Assets
  ↓  Stateless Web Tier (session → external store)
  ↓  Multiple Data Centers (geoDNS)
  ↓  Message Queues (async processing)
  ↓  Logging, Metrics, Automation
  ↓  Database Sharding
```

**Key takeaways from the scaling journey**:

| Technique | What It Solves | Key Considerations |
|-----------|---------------|-------------------|
| **Load Balancer** | Single point of failure, capacity limits | Public IP for LB, private IPs for servers |
| **DB Replication** | Read bottleneck, reliability | Master = writes, Slaves = reads; promote slave if master dies |
| **Cache** | Slow DB reads | Read-through strategy; consider expiration, consistency, eviction (LRU) |
| **CDN** | Slow static asset delivery | TTL, cost, fallback, cache invalidation |
| **Stateless Web** | Session affinity limits scaling | Store sessions in Redis/Memcached/NoSQL; enables auto-scaling |
| **Multi-DC** | Regional latency, disaster recovery | GeoDNS routing, data sync (Netflix model), consistent deployment |
| **Message Queue** | Tight coupling, synchronous bottlenecks | Producer → Queue → Consumer; scale independently |
| **Sharding** | Single DB capacity limit | Choose shard key wisely; beware resharding, celebrity (hotspot), join complexity |

**Summary checklist** for millions-scale systems:
- Keep web tier stateless
- Build redundancy at every tier
- Cache data as much as you can
- Support multiple data centers
- Host static assets in CDN
- Scale data tier by sharding
- Split tiers into individual services
- Monitor and automate

### Ch 2 — Back-of-the-Envelope Estimation

| Power of 2 | Value | Approx |
|------------|-------|--------|
| 2^10 | 1,024 | ~1 KB |
| 2^20 | ~1M | ~1 MB |
| 2^30 | ~1B | ~1 GB |
| 2^40 | ~1T | ~1 TB |
| 2^50 | ~1P | ~1 PB |

**Availability numbers (SLA)**:

| Nines | Availability | Downtime/year |
|-------|-------------|---------------|
| 99% | 2 nines | 3.65 days |
| 99.9% | 3 nines | 8.76 hours |
| 99.99% | 4 nines | 52.6 minutes |
| 99.999% | 5 nines | 5.26 minutes |

**Example — Twitter estimation**:
- 300M MAU × 50% = 150M DAU
- 150M × 2 tweets / 86,400s ≈ **3,500 QPS** (peak ≈ 7,000)
- Media storage: 150M × 2 × 10% × 1 MB = **30 TB/day**
- 5-year storage: 30 TB × 365 × 5 ≈ **55 PB**

**Tips**: Round aggressively, label units, write down assumptions, practice QPS + storage + cache estimates.

### Ch 3 — A Framework for System Design Interviews

**4-step process** (each interview typically 45–60 min):

| Step | Time | Activities |
|------|------|------------|
| **1. Understand & Scope** | 3–10 min | Clarify features, users, scale, constraints. **Don't jump to solution.** |
| **2. High-Level Design** | 10–15 min | Draw API design, major components, data flow. Get interviewer buy-in. |
| **3. Deep Dive** | 10–25 min | Focus on 2–3 critical components. Show depth. |
| **4. Wrap Up** | 3–5 min | Summarize, discuss bottlenecks, error handling, monitoring, future scale. |

**Dos and Don'ts**:
- DO ask clarifying questions before designing
- DO propose multiple approaches, explain trade-offs
- DO communicate with interviewer constantly
- DON'T jump into details without high-level design
- DON'T over-engineer or go silent

---

## Part II: Infrastructure Design (Ch 4–7)

### Ch 4 — Design a Rate Limiter

**Purpose**: Control request rate to prevent abuse, reduce cost, prevent server overload.

**Where to place it**: Client-side (easily bypassed), server-side, or **API Gateway** (most common in cloud/microservices).

| Algorithm | How It Works | Pros | Cons |
|-----------|-------------|------|------|
| **Token Bucket** | Tokens refill at fixed rate; each request costs 1 token | Allows bursts, memory efficient | Two parameters to tune |
| **Leaking Bucket** | Requests join FIFO queue; processed at fixed rate | Smooth output, memory efficient | Bursts fill queue; old requests starved |
| **Fixed Window** | Counter per time window | Simple, memory efficient | Spike at window boundary |
| **Sliding Window Log** | Track each request timestamp in sorted set | Accurate | Memory heavy |
| **Sliding Window Counter** | Weighted combo of current + previous window | Smooth, memory efficient | Approximation |

**Architecture** (distributed rate limiter):
- Use **Redis** for counters (INCR + EXPIRE are atomic)
- Race condition → use Lua script or sorted set
- Multi-server sync → centralized Redis store
- Return `HTTP 429 Too Many Requests` with `X-Ratelimit-Remaining`, `X-Ratelimit-Limit`, `X-Ratelimit-Retry-After` headers

### Ch 5 — Design Consistent Hashing

**Problem**: Simple `hash(key) % N` redistributes almost all keys when servers are added/removed.

**Solution**: Map keys and servers onto a **hash ring**. Walk clockwise from key position → first server found owns that key.

**Virtual nodes** solve uneven distribution: Each physical server maps to multiple points on the ring. With 100–200 virtual nodes, standard deviation drops to 5–10% of mean.

**When a node is added/removed**: Only keys between the affected node and its predecessor need redistribution — `K/N` keys moved instead of all.

**Used by**: Amazon DynamoDB, Apache Cassandra, Discord, Akamai CDN, Google Maglev.

### Ch 6 — Design a Key-Value Store

**CAP Theorem in practice**: Network partitions are inevitable → real choice is **CP** (block writes for consistency) vs **AP** (accept writes, resolve later).

**Core components** (based on Dynamo, Cassandra, BigTable):

| Component | Technique |
|-----------|-----------|
| **Data partitioning** | Consistent hashing |
| **Data replication** | Replicate to N nodes clockwise on ring; cross-DC |
| **Consistency** | Quorum: W + R > N = strong consistency |
| **Conflict resolution** | Vector clocks — detect ancestor vs sibling (conflict) |
| **Failure detection** | Gossip protocol — heartbeat counters + random propagation |
| **Temporary failure** | Sloppy quorum + hinted handoff |
| **Permanent failure** | Anti-entropy with Merkle trees |
| **DC outage** | Cross-datacenter replication |

**Write path**: Request → commit log → memory cache → flush to SSTable on disk  
**Read path**: Memory cache → (miss) → Bloom filter → SSTables → return

**Tunable consistency**: Adjust N, W, R per use case:
- Fast read: R=1, W=N
- Fast write: W=1, R=N  
- Strong consistency: W+R > N (typical: N=3, W=R=2)

### Ch 7 — Design a Unique ID Generator

Requirements: 64-bit, sortable by time, 10,000+ IDs/sec, distributed.

| Approach | Pros | Cons |
|----------|------|------|
| **Multi-master (auto-increment by K)** | Simple | Hard to scale across DCs, not time-sortable |
| **UUID** | Simple, no coordination | 128-bit, not sortable, not numeric |
| **Ticket Server** (Flickr model) | Numeric, easy to implement | SPOF (single or few servers) |
| **Snowflake** (Twitter) | 64-bit, time-sortable, distributed | Clock sync needed |

**Snowflake ID structure** (64 bits):

```
| 1 bit (sign) | 41 bits (timestamp ms) | 5 bits (DC ID) | 5 bits (machine ID) | 12 bits (sequence) |
```

- 41-bit timestamp → ~69 years of IDs
- 12-bit sequence → 4096 IDs per millisecond per machine
- Clock synchronization is critical (NTP)

---

## Part III: Application Design (Ch 8–15)

### Ch 8 — Design a URL Shortener (e.g., TinyURL)

**Write flow**: `POST api/v1/data/shorten` → generate unique short URL  
**Read flow**: `GET api/v1/shortUrl` → 301/302 redirect to long URL

| Redirect Code | Meaning | Use When |
|--------------|---------|----------|
| **301** (Permanent) | Browser caches; subsequent requests go directly to long URL | Reduce server load |
| **302** (Temporary) | Browser always hits short URL server first | Need analytics (click tracking) |

**Hash + collision resolution**: Hash long URL → take first 7 chars → check DB → if collision, append predefined string and re-hash. Use **Bloom filter** for fast existence checks.

**Base-62 encoding**: Convert unique auto-incrementing ID to base-62 string (a-z, A-Z, 0-9). Guarantees no collision but URL length depends on ID.

### Ch 9 — Design a Web Crawler

**Components**: Seed URLs → URL Frontier (priority queue) → HTML Downloader → Content Parser → Content Seen? (fingerprint dedup) → Link Extractor → URL Filter → URL Seen? (Bloom filter) → URL Frontier

**Key design points**:
- **Politeness**: One download queue per host; respect `robots.txt`; download interval per domain
- **Priority**: PageRank or other scoring to prioritize important URLs
- **Freshness**: Recrawl based on update history; prioritize frequently-changing pages
- **Storage**: Majority of URLs stored on disk; in-memory buffer for enqueue/dequeue
- **Robustness**: Consistent hashing for distribution; save crawl state for recovery; handle spider traps (max URL length)

### Ch 10 — Design a Notification System

**Types**: iOS Push (APNS), Android Push (FCM), SMS (Twilio), Email (SendGrid)

**Architecture**:
```
Services 1..N → Notification Servers → Message Queues (per type) → Workers → Third-party Services → Devices
                     ↕                                                      
              Cache + Metadata DB                                           
```

**Key design decisions**:
- **Separate queues** per notification type → one outage doesn't block others
- **Notification log DB** → never lose notifications
- **Dedup** by event ID → prevent duplicate sends
- **Rate limiting** → don't overwhelm users
- **Retry mechanism** → exponential backoff for failed sends
- **Notification templates** → consistent format, reduce errors
- **User settings** → opt-in/opt-out check before sending
- **Analytics** → track open rate, click rate, engagement

### Ch 11 — Design a News Feed System

**Two main flows**: Feed publishing and News feed building

**Feed publishing**: User posts → Post Service → DB + Cache → **Fanout Service** → friends' news feed cache

**Fanout strategies**:

| Strategy | Description | Pros | Cons |
|----------|-------------|------|------|
| **Fan-out on write** (push) | Pre-compute feed for all followers immediately | Fast reads | Slow for users with many followers (celebrity/hotkey problem) |
| **Fan-out on read** (pull) | Compute feed at read time on-demand | No wasted compute | Slow reads |
| **Hybrid** | Push for normal users; pull for celebrities | Best of both | More complex |

**News feed cache**: Store `<post_id, user_id>` mapping (not full objects) → fetch full data from user cache + post cache at read time. Configurable limit on cached entries.

**Feed retrieval**: Client → LB → Web Server → News Feed Service → Cache (post IDs) → User Cache + Post Cache + CDN (media) → hydrated feed → Client

### Ch 12 — Design a Chat System

**Protocol**: **WebSocket** for persistent bidirectional real-time communication (HTTP for all other operations).

**Architecture**:
- **Chat servers** — real-time messaging via WebSocket
- **Presence servers** — online/offline status (heartbeat mechanism)
- **API servers** — login, signup, profile (stateless, HTTP)
- **Push notification servers** — offline message delivery
- **Key-value store** — chat history (HBase at Facebook, Cassandra at Discord)

**Message ID**: Local sequence number per channel (not global) — simpler and sufficient since ordering only matters within a conversation.

**Service discovery**: Apache Zookeeper recommends best chat server based on geography + capacity.

**1-on-1 flow**: User A → Chat Server 1 → ID Generator → Message Sync Queue → KV Store → Chat Server 2 → User B (or Push Notification if offline)

**Group chat**: Copy message to each member's **message sync queue** (inbox model). Works well for small groups (WeChat caps at 500). For large groups, shift to pull model.

**Presence**: Heartbeat every N seconds. If no heartbeat for X seconds → mark offline. Status changes published via pub/sub channels per friend pair.

### Ch 13 — Design a Search Autocomplete System

**Data structure**: **Trie (prefix tree)** with two optimizations:
1. **Limit prefix length** (e.g., 50 chars) → O(1) prefix lookup
2. **Cache top-K queries at each node** → O(1) to return suggestions

**Data gathering service** (offline):
```
Analytics Logs → Aggregators (weekly) → Workers → Build Trie → Trie DB + Trie Cache
```

**Query service** (online):
```
Client types → AJAX request per keystroke → Trie Cache → Return top 5 suggestions
```

**Optimizations**:
- **Browser caching**: Cache suggestions for same prefix (short TTL)
- **Data sampling**: Only log 1 in N queries for aggregation (reduce write volume)
- **Trie DB**: Serialize trie as document (snapshot) or store in KV store
- **Filter layer**: Remove hate speech, NSFW, etc. from suggestions

**Scale storage**: Shard tries by first character or by consistent hashing on prefix ranges.

### Ch 14 — Design YouTube

**Two main flows**: Video uploading and Video streaming

**Upload flow**:
```
Client → Load Balancer → API Servers → Original Storage (temporary)
                                           ↓
                                    Transcoding Servers (parallel by GOP)
                                           ↓
                                    Transcoded Storage → CDN
                                           ↓
                                    Completion Callback → Update Metadata DB + Cache
```

**Video transcoding** (encoding):
- Produce multiple resolutions (360p, 480p, 720p, 1080p, 4K) and formats (MPEG, HLS, DASH)
- **DAG (Directed Acyclic Graph)** model for task pipeline: video → split → encode → merge → thumbnail → watermark → output
- **Resource manager**: Task queue + Worker queue + Running queue + Task scheduler

**Streaming**: Adaptive bitrate streaming — client adjusts quality based on network bandwidth. CDN delivers video segments.

**Cost optimization**:
- Serve popular videos from CDN; less popular from origin storage
- Short/unpopular videos: encode fewer versions
- Region-specific distribution — don't CDN a regional video globally
- Build own CDN for massive scale (Netflix model)

**Safety**: Pre-upload DRM/AES encryption, visual watermarking, copyright detection.

### Ch 15 — Design Google Drive

**Core features**: Upload, download, sync across devices, file revisions, sharing, notifications.

**High-level components**:
- **Block servers** — split files into 4MB blocks, compress, encrypt, upload to cloud storage
- **Cloud storage** (S3) — store file blocks with cross-region replication
- **Cold storage** — infrequently accessed data (S3 Glacier)
- **Metadata DB** — relational DB for users, files, blocks, versions (ACID for strong consistency)
- **Notification service** — long polling to inform clients of changes
- **Offline backup queue** — store pending changes for offline clients

**Key techniques**:
- **Delta sync** — only upload modified blocks, not entire file
- **Block-level dedup** — same hash = same block = store once
- **Compression** — gzip/bzip2 for text, specialized for media
- **Sync conflicts** — first processed wins; later gets conflict with both versions presented to user
- **Resumable upload** — critical for large files over unstable networks
- **File versioning** — file_version table (read-only rows); limit stored versions to save space

---

## The 4-Step Framework — Quick Reference

Use this for **every** system design interview question:

```
Step 1: UNDERSTAND (3-10 min)
├── What features to build?
├── How many users/DAU?
├── Read-heavy or write-heavy?
├── What's the expected scale in 3 months / 1 year?
└── Any existing infrastructure to leverage?

Step 2: HIGH-LEVEL DESIGN (10-15 min)
├── API design (endpoints, params)
├── Draw major components + data flow
├── Database choice (SQL vs NoSQL)
└── Get interviewer agreement before deep dive

Step 3: DEEP DIVE (10-25 min)
├── Focus on 2-3 components interviewer cares about
├── Show trade-offs (consistency vs availability, push vs pull)
├── Discuss data model, algorithms, specific technologies
└── Handle edge cases and failure scenarios

Step 4: WRAP UP (3-5 min)
├── Recap the design
├── Identify bottlenecks
├── Discuss error handling and monitoring
└── Suggest future improvements
```

---

## Recurring Patterns Across All Chapters

| Pattern | Used In |
|---------|---------|
| **Consistent hashing** | Key-value store, web crawler, news feed (hotkey mitigation) |
| **Message queues** | Notification system, news feed, YouTube transcoding, Google Drive |
| **Cache (Redis/Memcached)** | Every single design — cache is universal |
| **Database sharding** | URL shortener, chat system, autocomplete, YouTube |
| **Bloom filter** | Web crawler (URL dedup), key-value store (SSTable lookup), URL shortener |
| **Rate limiting** | Rate limiter (ch 4), notification system, news feed, API servers |
| **Fan-out (push/pull/hybrid)** | News feed, notification, chat presence |
| **WebSocket** | Chat system (real-time bidirectional) |
| **Long polling** | Google Drive notifications |
| **Heartbeat / gossip** | Key-value store (failure detection), chat (presence), load balancer |
| **DAG pipeline** | YouTube video processing |
| **Trie** | Search autocomplete |
| **Snowflake IDs** | Unique ID generator, chat message ordering |
| **Delta sync + block splitting** | Google Drive file upload |

---

## Common Pitfalls

| Pitfall | Why It Hurts | Fix |
|---------|-------------|-----|
| Jumping into solution immediately | Miss requirements, wrong direction | Spend 3–10 min on Step 1 |
| Designing in silence | Interviewer can't evaluate your thinking | Narrate your thought process |
| One-size-fits-all database | SQL for everything or NoSQL for everything | Choose based on access patterns and consistency needs |
| Ignoring back-of-the-envelope | Can't reason about capacity | Always estimate QPS, storage, bandwidth first |
| Not discussing trade-offs | Looks like you don't understand alternatives | Present 2+ approaches, explain pros/cons, then choose |
| Skipping failure handling | Real systems fail constantly | Discuss SPOF, retries, replication, circuit breakers |
| Over-engineering | Adds complexity without solving a real problem | Start simple, scale when needed |

---

## Cross-References

| Topic in This Book | Related Notes | Connection |
|--------------------|---------------|------------|
| Scaling fundamentals, CDN, caching, rate limiting | [ByteByteGo System Design](./bytebytego-system-design.md) | Visual companion covering same foundational topics |
| System design interview process | [Cracking the Coding Interview](../10-soft-skills/interviewing/cracking-the-coding-interview.md) | Ch 9 covers system design interview approach |
| Design patterns (Observer, Strategy, etc.) | [Learning Patterns](../04-frontend/react/learning-patterns.md) | Software design patterns at application level |
| Clean code, refactoring | [Clean Code](../01-fundamentals/clean-code/clean-code.md) | Code quality within system components |

---

## References

- [Source PDF](../sources/books/system-design-interview-an-insiders-guide-2nbsped-9798664653403-volume-1.pdf)
- [System Design Primer (GitHub)](https://github.com/donnemartin/system-design-primer) — Open-source companion
- [ByteByteGo Newsletter](https://blog.bytebytego.com/) — Alex Xu's weekly system design articles
- [System Design Interview Vol. 2](https://www.amazon.com/System-Design-Interview-Insiders-Guide/dp/1736049119) — Advanced topics (proximity service, nearby friends, Google Maps, etc.)
