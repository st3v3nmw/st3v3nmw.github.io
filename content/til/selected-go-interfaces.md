---
title: "Selected Go Interfaces"
summary: "A list of useful Go interfaces"
date: 2025-02-18T23:39:07+03:00
type: til
math: true
meta: true
topics:
  - interfaces
  - golang
---

This is a collection of Go interfaces I've found myself using or encountering frequently while writing Go.
They represent core functionality like error handling, I/O operations, data encoding/decoding, and HTTP handling.

## Built-in

Go has a built-in interface for representing errors:

```go
// error is Go's built-in interface for representing errors
type error interface {
  // Error returns a human-readable error message
  Error() string
}
```

## fmt

The `fmt` package provides formatted I/O operations:

```go
// Stringer allows types to define their default string representation
// Used when printing values or converting them to strings
// Example: custom types that need a readable format
type Stringer interface {
  String() string
}

// GoStringer defines how a type should be represented in Go syntax
// Used with the %#v format verb in fmt functions
// Example: useful for debugging
type GoStringer interface {
  GoString() string
}
```

## encoding/json

The `encoding/json` package implements encoding and decoding of JSON:

```go
// Marshaler lets types control their JSON encoding
// Useful when you need custom JSON formatting
// Example: converting complex types
type Marshaler interface {
  MarshalJSON() ([]byte, error)
}

// Unmarshaler lets types control their JSON decoding
// Useful for custom parsing of JSON data
// Example: parsing complex data structures
type Unmarshaler interface {
  UnmarshalJSON([]byte) error
}
```

## encoding

The `encoding` package defines interfaces shared by other packages that
convert data to and from byte-level and textual representations:

```go
// BinaryMarshaler allows types to convert themselves to binary format
// Useful for serialization and data storage
type BinaryMarshaler interface {
  MarshalBinary() (data []byte, err error)
}

// BinaryUnmarshaler allows types to restore themselves from binary format
// Paired with BinaryMarshaler for complete serialization support
type BinaryUnmarshaler interface {
  UnmarshalBinary(data []byte) error
}

// TextMarshaler allows types to convert themselves to text format
// Useful for human-readable serialization
type TextMarshaler interface {
  MarshalText() (text []byte, err error)
}

// TextUnmarshaler allows types to restore themselves from text format
// Paired with TextMarshaler for complete text-based serialization
type TextUnmarshaler interface {
  UnmarshalText(text []byte) error
}
```

## io

The `io` package provides basic interfaces to I/O primitives:

```go
// Reader represents anything that can be read from
// Examples: files, network connections, buffer
type Reader interface {
  // Read fills the provided byte slice and returns how many bytes were read
  Read(p []byte) (n int, err error)
}

// Writer represents anything that can be written to
// Examples: files, network connections, buffers
type Writer interface {
  // Write takes a byte slice and returns how many bytes were written
  Write(p []byte) (n int, err error)
}

// Closer represents resources that need to be cleaned up
// Examples: file handles, network connections, database connections
type Closer interface {
  Close() error
}

// ReadWriter combines reading and writing capabilities
type ReadWriter interface {
  Reader
  Writer
}

// ReadWriteCloser combines reading, writing, and cleanup capabilities
type ReadWriteCloser interface {
  Reader
  Writer
  Closer
}
```

## context

The `context` package provides a standard way to carry deadlines, cancellation signals, and request-scoped values:

```go
// Context carries deadlines, cancellation signals, and request-scoped values
// Used to control operations across API boundaries and goroutines
// Examples: HTTP requests, database operations, RPC calls
type Context interface {
  // Deadline returns the time when work done on behalf of this context
  // should be canceled
  Deadline() (deadline time.Time, ok bool)

  // Done returns a channel that's closed when work done on behalf of this
  // context should be canceled
  Done() <-chan struct{}

  // Err explains why this context was cancelled
  // Returns nil if not cancelled
  Err() error

  // Value returns the value associated with this context for key, or nil
  Value(key interface{}) interface{}
}
```

## sort

The `sort` package provides primitives for sorting slices and user-defined collections:

```go
// Interface defines how to sort any collection
// Implement these methods to make your collection sortable
// The standard library's sort package will handle the actual sorting
type Interface interface {
  // Len returns the total number of elements
  Len() int

  // Less determines the ordering between elements
  // Return true if element i should come before element j
  Less(i, j int) bool

  // Swap swaps elements at positions i and j
  Swap(i, j int)
}
```

## net/http

The `net/http` package provides HTTP client and server implementations:

```go
// Handler processes HTTP requests
// It's the foundation of Go's HTTP server functionality
// Implement this to create custom HTTP endpoints
type Handler interface {
  ServeHTTP(ResponseWriter, *Request)
}

// ResponseWriter lets you construct HTTP responses
// Used to send headers, write response body, and set status codes
type ResponseWriter interface {
  // Header returns the header map that will be sent by WriteHeader
  Header() Header

  // Write writes the data to the connection as part of a HTTP reply
  Write([]byte) (int, error)

  // WriteHeader sends an HTTP response header with the provided
  // status code
  WriteHeader(statusCode int)
}
```

## database/sql

The `database/sql` package provides a generic interface around SQL (or SQL-like) databases:

```go
// Scanner converts database values into Go values
// Used when reading data from databases
// Handles common database types like integers, strings, and timestamps
type Scanner interface {
  Scan(src interface{}) error
}

// Valuer converts Go values into database values
// Used when writing data to databases
// Ensures proper type conversion for database storage
type Valuer interface {
  Value() (Value, error)
}
```
