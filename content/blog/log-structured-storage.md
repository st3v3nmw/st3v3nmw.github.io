---
title: "Log-Structured Storage"
subtitle: "Build Your Own Distributed Key-Value Store: Part 2"
date: 2025-01-26T10:44:08+03:00
draft: true
type: post
toc: true
math: true
tags:
  - build-your-own-x
  - key-value-store
  - little-key-value
  - distributed-systems
  - golang
---

<div align="center" class="image-container">
  <img src="/images/illustrations/man-running.png" alt="Man running illustration"/>
</div>

{{<epigraph pre="Pat Helland">}}
Accountants don't use erasers; otherwise they may go to jail. All entries in a ledger remain in the ledger. Corrections can be made but only by making new entries in the ledger.
{{</epigraph>}}

In the previous post, we built a simple in-memory key-value store.

Go over Hash index:
- quick lookups (O(1))
- limited by memory
- no persistence

Unless you like living life on the edge, you'll want to persist your data on disk and that's where log-structured storage comes in.

Databases like Cassandra, LevelDB, RocksDB, and ScyllaDB use log-structured storage to store data.

Immutability... in-memory buffer, append-only files on disk. Mention effects on write & read performance. Useful where writes are more frequent than reads.

We'll need a goroutine responsible for flushing the in-memory buffer to disk. We'll call it _the tree shaker_. {{<marginnote>}}Named after the contraption that is [mechanical tree shakers](https://upload.wikimedia.org/wikipedia/commons/5/5e/Olive_harvest_2014.webm).{{</marginnote>}}

A tombstone is a special value that indicates that a key has been deleted. We'll use the † character for this (fun fact: it's _not_ a dagger 🙂).

SSTable format:

```text
deleted→†
key→value
```

Plain text... in "real-world" applications, a binary format is used but this is better for a tutorial since it's easy to inspect.

Example:

```text
kenya:capital→Nairobi
rwanda:capital→Kigali
tanzania:capital→†
uganda:capital→Kampala
```

## What's Next?

next post could cover log-structured storage optimizations:

- compaction
- sparse indexes
- bloom filters
- write-ahead log

## Resources

- ... [Designing Data-Intensive Applications](https://dataintensive.net/) by Martin Kleppmann
- Log-Structured Storage: Chapter 7, [Database Internals](https://www.databass.dev/) by Alex Petrov
