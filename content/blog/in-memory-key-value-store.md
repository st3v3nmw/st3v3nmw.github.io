---
title: "In Memory Key-Value Store"
subtitle: "Build Your Own Distributed Key-Value Store: Part 1"
date: 2025-01-25T15:45:13+03:00
type: post
toc: true
math: true
tags:
  - build-your-own-x
  - key-value-store
  - distributed-systems
  - golang
---

<div align="center" class="image-container">
  <img src="/images/illustrations/woman-gardening.png" alt="Woman gardening illustration"/>
</div>

{{<epigraph pre="Richard Feynman">}}
What I cannot create, I do not understand. Know how to solve every problem that has been solved.
{{</epigraph>}}

In this blog series, we will build a distributed key-value store from scratch in Go. We'll cover topics such as replication, consensus, consistency, and sharding.
While I'm no expert in distributed systems, I'm learning as I go - so if anything looks egregiously wrong (hopefully not enough to irreparably damage my self-esteem 😅), just shoot me an email or start a [new discussion](https://github.com/st3v3nmw/st3v3nmw.github.io/discussions).

## Definition

A [key-value store](https://en.wikipedia.org/wiki/Key%E2%80%93value_database) is a database that stores key-value pairs.
A key is a unique identifier that is used to retrieve the associated value. The value can be any data type, such as a string, an integer, or even a data blob like an image.\
For our store, though, we'll only store string values for simplicity, as we'll be managing a database of country profiles:

<div align="center" class="image-container">
  <img src="/images/key-value-store/key-value-example.png" alt="Key-value pairs example"/>
</div>

Key-value stores are used in a variety of applications, including caching, session management, and configuration management. Examples of key-value stores include [Redis](https://redis.io/), [Valkey](https://valkey.io/), [Memcached](https://memcached.org/), and [Amazon DynamoDB](https://aws.amazon.com/dynamodb/).

## Setup

The first step is to create a new directory for the project and initialize a new Go module for our `crafty-key-value` project. Run the following commands to set it up:

```console
$ mkdir crafty-key-value
$ cd crafty-key-value
$ go mod init github.com/<username>/crafty-key-value
go: creating new go.mod: module github.com/<username>/crafty-key-value
```

Remember to replace `<username>` with your GitHub username. The full source code for this post can be found in the `01-in-memory-key-value-store` folder of the [companion repository](https://github.com/st3v3nmw/crafty-key-value/tree/main/01-in-memory-key-value-store).

## Implementation

The first version of our key-value store will be an in-memory key-value store that only runs on a single node/machine.
We'll incrementally build on this foundation until we have a fully-fledged distributed key-value store and hopefully learn some distributed systems concepts along the way :).

### Storage Layer

We'll start off by building the storage layer of our key-value store. We'll store the key-value pairs in a hash table {{<marginnote>}}A hash table is a data structure that maps keys to values which closely matches the key-value store's data model. In Go, this is a `map`.{{</marginnote>}} in memory. While this is a good starting point, we'll migrate to a more robust storage solution in the future.

The storage layer will implement an API with these methods:

1. `Set(key, value)`: Insert or update a `key`-`value` pair in the store.
2. `Get(key)`: Get the value of `key` from the store.
3. `Delete(key)`: Delete `key` from the store.

Create a `internal/storage` folder and a `types.go` file inside it which will hold the types and interfaces used by the storage layer. Add the following code to it:

```go
package storage

import "fmt"

// Storage defines the interface for a generic key-value storage system
type Storage interface {
	// Set adds or updates a key-value pair in the storage
	Set(key string, value string) error

	// Get retrieves the value associated with a given key
	Get(key string) (string, error)

	// Delete removes a key-value pair from the storage
	Delete(key string) error
}

// NotFoundError is a custom error type for when a key is not found
// It implements the standard error interface
type NotFoundError struct{}

// Error returns a string representation of the error
func (e *NotFoundError) Error() string {
	return fmt.Sprintf("key not found")
}
```

Next, we'll implement the `Storage` interface using a `map`. Create a `map.go` file in the same folder and add the following code to it:

```go
package storage

import (
	"sync"
)

// MapStorage is a simple in-memory implementation of the Storage interface
// It uses a map to store key-value pairs
type MapStorage struct {
	mu   sync.RWMutex
	data map[string]string
}

// NewMapStorage creates a new instance of MapStorage
func NewMapStorage() *MapStorage {
	return &MapStorage{
		data: map[string]string{},
	}
}

// Set adds or updates a key-value pair in the storage
func (m *MapStorage) Set(key string, value string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.data[key] = value
	return nil
}

// Get retrieves the value associated with a given key
func (m *MapStorage) Get(key string) (string, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	value, ok := m.data[key]
	if !ok {
		return "", &NotFoundError{}
	}
	return value, nil
}

// Delete removes a key-value pair from the storage
func (m *MapStorage) Delete(key string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	delete(m.data, key)
	return nil
}
```

Yup, that's it! We've implemented a simple in-memory key-value store. The only thing to note is that we're using a mutex {{<marginnote>}}A mutex (from [mutual exclusion](https://en.wikipedia.org/wiki/Mutual_exclusion)) is a synchronization primitive that prevents state from being modified or accessed by multiple threads of execution at once.{{</marginnote>}} to ensure that only one goroutine can modify the `map` at a time, preventing race conditions and data corruption. This is because a `map` {{<marginnote>}}Alternatively, one can use `sync.Map` which handles concurrency out of the box.{{</marginnote>}} is not thread-safe by default.

### API Layer

Next, we'll create a REST API that will expose the storage layer's API.

We'll add a `/kv/{key}` endpoint that will accept the following HTTP methods:

1. `PUT /kv/{key}`: Calls `Set` on the storage layer.
2. `GET /kv/{key}`: Calls `Get` on the storage layer.
3. `DELETE /kv/{key}`: Calls `Delete` on the storage layer.

Create a `internal/api` folder and a `server.go` file inside it which will hold the API server implementation. Add the following code to it:

```go
package api

import (
	"errors"
	"fmt"
	"io"
	"net/http"

	"github.com/st3v3nmw/crafty-key-value/internal/storage"
)

// Server represents the key-value server
type Server struct {
	storage storage.Storage
}

// New creates a new instance of the Server
func New() *Server {
	return &Server{storage: storage.NewMapStorage()}
}

// Serve starts the HTTP server and handles key-value store operations
func (s *Server) Serve(addr string) error {
	http.HandleFunc("/kv/", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPut:
			s.set(w, r)
		case http.MethodGet:
			s.get(w, r)
		case http.MethodDelete:
			s.delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})

	return http.ListenAndServe(addr, nil)
}
```

This defines a new endpoint `/kv/{key}` that handles the key-value store operations. Don't forget to replace `st3v3nmw` in the import path with your GitHub username.

Next, we'll add the `set`, `get`, and `delete` methods to the `Server` struct.
These methods are simply wrappers around the storage layer's API:

```go
// set handles the HTTP PUT request for setting a key-value pair
func (s *Server) set(w http.ResponseWriter, r *http.Request) {
	value, err := io.ReadAll(r.Body)
	if err != nil {
		msg := fmt.Sprintf("unable to read request body: %v", err)
		http.Error(w, msg, http.StatusInternalServerError)
		return
	}

	key := r.URL.Path[len("/kv/"):]
	err = s.storage.Set(key, string(value))
	if err != nil {
		msg := fmt.Sprintf("unable to set key: %v", err)
		http.Error(w, msg, http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// get handles the HTTP GET request for retrieving a key-value pair
func (s *Server) get(w http.ResponseWriter, r *http.Request) {
	key := r.URL.Path[len("/kv/"):]
	value, err := s.storage.Get(key)
	if err != nil {
		if errors.Is(err, &storage.NotFoundError{}) {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}

		msg := fmt.Sprintf("unable to get key: %v", err)
		http.Error(w, msg, http.StatusInternalServerError)
		return
	}

	w.Write([]byte(value))
}

// delete handles the HTTP DELETE request for deleting a key-value pair
func (s *Server) delete(w http.ResponseWriter, r *http.Request) {
	key := r.URL.Path[len("/kv/"):]
	err := s.storage.Delete(key)
	if err != nil {
		msg := fmt.Sprintf("unable to delete key: %v", err)
		http.Error(w, msg, http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}
```

## Entry Point

Lastly, we'll create a `cmd/crafty-key-value/main.go` file that contains the `main` entry point {{<marginnote>}}An entry point is the place in a program where the execution of a program begins, and where the program has access to command line arguments.{{</marginnote>}} for our server:

```go
package main

import (
	"fmt"

	"github.com/st3v3nmw/crafty-key-value/internal/api"
)

func main() {
	fmt.Println("Starting Crafty Key-Value Store...")

	server := api.New()
	server.Serve(":8888")
}
```

## Project Structure

After you're done, the project should look like this:

```console
$ tree
.
├── cmd
│   └── crafty-key-value
│       └── main.go
├── go.mod
└── internal
    ├── api
    │   └── server.go
    └── storage
        ├── map.go
        └── types.go

6 directories, 5 files
```

The project follows the [standard Go project layout](https://github.com/golang-standards/project-layout). The `cmd` folder contains the main application for the project i.e. `./cmd/crafty-key-value` while the `internal` folder contains the private application and library code.

The code is organized into packages, following a [package oriented design pattern](https://www.ardanlabs.com/blog/2017/02/package-oriented-design.html).
We have a `storage` package that contains the storage layer implementation and an `api` package that contains the API layer. The `main` package ties everything together and serves as the application's entry point.

## Run the Server

We're finally ready to run the key-value service! Run the following command to start it:

```console
$ go run ./cmd/crafty-key-value
Starting Crafty Key-Value Store...
```

We're going to use `curl` to test it. Let's start by saving some key-value pairs:

```console
$ curl -X PUT -d 'Nairobi' http://127.0.0.1:8888/kv/kenya:capital
$ curl -X PUT -d 'Kampala' http://127.0.0.1:8888/kv/uganda:capital
$ curl -X PUT -d 'Dar es Salaam' http://127.0.0.1:8888/kv/tanzania:capital
$ curl -X PUT -d 'Dodoma' http://127.0.0.1:8888/kv/tanzania:capital
```

Now, let's get the values we just set:

```console
$ curl http://127.0.0.1:8888/kv/kenya:capital
Nairobi
$ curl http://127.0.0.1:8888/kv/tanzania:capital
Dodoma
```

Finally, we'll delete one of the key-value pairs:

```console
$ curl -X DELETE http://127.0.0.1:8888/kv/tanzania:capital
$ curl http://127.0.0.1:8888/kv/tanzania:capital
key not found
```

Congratulations - you've just built a simple in-memory key-value store!

<div align="center" class="image-container">
  <img src="/images/illustrations/woman-celebrating.png" alt="Woman celebrating illustration"/>
</div>

## What's Next?

Since we're storing our data in memory, the store will lose it once we kill the process running it. In [the next post](/blog/log-structured-storage/), we'll migrate our storage layer to persistent storage using [LSM trees](https://en.wikipedia.org/wiki/Log-structured_merge-tree) and SSTables.

As an exercise, add input validation to the `Server.set` method to ensure that the provided `key` and `value` are not empty. Use these tests to confirm that your solution works:

```console
$ curl -X PUT -d '' http://127.0.0.1:8888/kv/kenya:capital
value cannot be empty
$ curl -X PUT -d 'foo' http://127.0.0.1:8888/kv/
key cannot be empty
```

Good luck!
