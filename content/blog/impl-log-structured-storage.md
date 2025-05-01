---
title: "Implementing Log Structured Storage"
subtitle: "Build Your Own Distributed Key-Value Store: Part 3"
summary: "In this post, we'll add log-structured storage to a distributed key-value store I'm building from scratch"
date: 2025-05-01T15:52:43+03:00
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
  <img src="/images/key-value-store/man-running.png" alt="Illustration of a man running away"/>
</div>

{{<epigraph pre="Pat Helland">}}
Accountants don't use erasers; otherwise they may go to jail. All entries in a ledger remain in the ledger. Corrections can be made but only by making new entries in the ledger.
{{</epigraph>}}
