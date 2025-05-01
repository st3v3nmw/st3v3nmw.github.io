---
title: "An LSM Tree's Life"
subtitle: "Build Your Own Distributed Key-Value Store: Part 2"
summary: "In this post, we'll explore the theory behind log structure storage"
date: 2025-04-19T15:25:50+03:00
draft: true
type: post
toc: true
math: true
tags:
  - build-your-own-x
  - key-value-stores
  - little-key-value
  - distributed-systems
  - golang
---

<div align="center" class="image-container">
  <img src="/images/key-value-store/woman-holding-flower-pot.png" alt="Illustration of a woman holding a flower pot"/>
</div>

{{<epigraph>}}
Spes non est consilium

(Hope is not a strategy)
{{</epigraph>}}

In the previous post, we built a simple in-memory key-value store.

## Hash Indexes

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

## Optimizations

- compaction
- sparse indexes
- bloom filters
- write-ahead log

## What's Next?

## Resources

- ... [Designing Data-Intensive Applications](https://dataintensive.net/) by Martin Kleppmann
- Log-Structured Storage: Chapter 7, [Database Internals](https://www.databass.dev/) by Alex Petrov
