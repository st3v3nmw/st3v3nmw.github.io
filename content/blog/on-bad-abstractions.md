---
title: "On Bad Abstractions"
subtitle: "And What Makes the Good Ones Work"
summary: ""
date: 2025-12-07T13:36:30+03:00
draft: true
type: post
toc: true
math: true
tags:
  - abstraction
  - interfaces
  - complexity
  - software-design
  - engineering-philosophy
---

<div align="center" class="image-container">
  <img src="/images/external/xkcd-dependency.png" alt="xkcd: Dependency"/>
</div>

{{<epigraph pre="Joel Spolsky">}}
All non-trivial abstractions, to some degree, are leaky.
{{</epigraph>}}

## Abstractions

{{<dropcap>}}W{{</dropcap>}}ithin every problem domain, complexity exists. Software creates layers of abstraction that help us manage this complexity, allowing us to work at higher levels without drowning in the gory implementation details beneath.

Consider TCP. It sits on top of the IP network which is fundamentally unreliable: packets can arrive out of order, get duplicated, arrive corrupted, or just disappear completely. TCP hides all of that chaos and gives applications the illusion of a _reliable, ordered byte stream_ between two endpoints on the network.

This works beautifully most of the time: you open a connection, write bytes, and they arrive in order on the other end. No need to think about packet loss, checksums, or retransmissions.

But the abstraction leaks. When packet `#5` gets lost while packets `#6`, `#7`, and `#8` arrive just fine, TCP can't hand you `#6-#8` just yet. That would break its "ordered byte stream" promise. So your application waits, even though the data is sitting in the kernel's receive buffer, already delivered by the network. Just because we've abstracted away this messiness and looked the other way doesn't mean that the network's inherent unreliability magically disappears.

Yet, TCP remains a good abstraction. The leak is real, but it happens _outside_ TCP's problem domain. TCP's job is reliable, ordered delivery over an unreliable network, and it does that job exceptionally well. [Head-of-line blocking](https://en.wikipedia.org/wiki/Head-of-line_blocking) isn't a flaw in TCP; it's the inevitable cost of guaranteed ordering. When that cost becomes unacceptable (video streaming, gaming), you're outside TCP's problem domain anyway and should use a different protocol. The complexity TCP hides is _enormous_, and forcing every application to handle it manually would be a nightmare.

### Definition

In _A Philosophy of Software Design_, John Ousterhout defines an abstraction as **"a simplified view of an entity, which omits unimportant details"**.

~Good abstractions minimize leakage within their domain, maintain the expressiveness required, and provide escape hatches when needed.~

## Papering Over Complexity

The worst abstractions - the ones that fill me with such ire - are those that manage to be both leaky AND lossy at the same time. They feel clunky, obstinate, unwilling to bend to your will. They solve the problem in their own complicated and opinionated way, yet make it so hard to go off the beaten path. And often, there's no _why_ behind the design - no philosophy, no clear tradeoffs. You're left fighting with someone else's mental model. It's as if someone just papered over a complex problem and called it a day.

Let me pick on the classic punching bag: ORMs. Not because they're the worst offenders, they're just the most familiar example of this pattern. I've built plenty with Django's ORM and genuinely appreciated what it gave me. These days I write Go and just use SQL directly. But that shift has shown me what these abstractions actually cost.

### ORMs

ORMs promise to abstract away SQL so you can "just think in objects." The pitch is appealing: map your database tables to classes, write object-oriented code, and let the ORM handle the messy SQL behind the scenes. For a while, it works great.

Then you write something innocent like this:

```python
users = User.objects.order_by("first_name")
for user in users:
  for post in user.posts:
    print(post.comments.count())
```

Looks harmless, right? You've just triggered `NxM+1` queries. One query for users, `N` queries for posts (one per user), and `NxM` queries for comment counts (one per post). What should've been a single `JOIN` with some aggregation just became hundreds of queries:

```sql
SELECT
  u.id, u.first_name, u.last_name,
  p.id, p.title,
  COUNT(c.id) as comment_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
LEFT JOIN comments c ON c.post_id = p.id
GROUP BY u.id, p.id
ORDER BY u.first_name;
```

The performance impact can be devastating, and [it's often not obvious](https://www.stephenmwangi.com/slides/django-perf-and-you/). These queries end up buried in templates or view logic where they're hard to spot until production.

"Ah," you say, "but I can fix this with [select_related](https://docs.djangoproject.com/en/6.0/ref/models/querysets/#select-related) and [prefetch_related](https://docs.djangoproject.com/en/6.0/ref/models/querysets/#prefetch-related)!" Sure. Except now you need to know:

- Which relationships are foreign keys versus many-to-many (select vs prefetch)
- When prefetching causes more problems than it solves
- How to structure your query to avoid fetching data you don't need
- When to just give up and write raw SQL

You're not thinking in objects anymore, you're thinking in SQL just with extra steps and a black box to debug. The abstraction leaks everywhere.

Plus, it's also lossy. Need a complex join? A CTE? A window function? Some Postgres specific feature? Good luck expressing that through the ORM's query builder. You end up contorting your code to fit what the ORM can generate, or dropping down to raw SQL entirely. The ORM can't express the full power of the underlying system - it's lost in translation.

This is the fundamental problem: ORMs are trying to paper over the [object-relational impedance mismatch](https://en.wikipedia.org/wiki/Object%E2%80%93relational_impedance_mismatch). SQL operates on relations: you describe what you want and the database figures out how to get it. Objects operate on graphs: you traverse pointers and call methods. These are fundamentally different paradigms, and no amount of clever mapping makes that difference disappear.

The best ORMs, like Django's, acknowledge this. They give you escape hatches: raw SQL when you need it, query explanation tools, clear documentation about the tradeoffs. They're leaky abstractions, but at least they're honest about it and give you the tools to work around both the leaks and the losses.

But even then, you're learning two things: the ORM's API _and_ SQL. And once you know SQL well enough to optimize your ORM usage, you start wondering why you're bothering with the middleman at all.

## Elegant Interfaces

There's something deeply satisfying about an API that _just makes sense_ - where you can predict what methods exist before you look at the documentation, where errors are explicit, where the complexity of the underlying system is ~organized rather than hidden~. Take this interface {{<marginnote>}}Of course in production Go code you'd add `context.Context` as the first parameter to each method for cancellation and timeouts, but we're omitting it here for clarity.{{</marginnote>}} for key-value storage for example: ~three methods, clear semantics, honest error handling.~

```go
type Store[T any] interface {
  // Set stores a value for the given key.
  // If ttl is provided, the key expires after the given duration.
  Set(key string, value T, ttl *time.Duration) error

  // Get retrieves the value associated with a given key.
  // Returns true if the key exists and hasn't expired.
  Get(key string) (T, bool, error)

  // Delete removes a key-value pair from the store.
  // No-op if the key doesn't exist.
  Delete(key string) error
}
```

Behind this simple contract could be an in-memory map, a Redis instance, or a distributed cache sharded across the globe. A lot could be happening in the background, but you don't need to learn all those details to use if effectively. This, in my opinion, is what good abstraction looks like.

- anything works at all

FIN.
