---
title: "Bitmasks in Go"
summary: "How to use bitwise operations to manipulate flags in Go"
date: 2025-02-03T22:40:58+03:00
type: til
math: true
meta: true
topics:
  - bitmask
  - golang
---

This code demonstrates how to use bitwise operations to manipulate flags in Go.

## Defining Flags

You can define flags this way:

```go
type Flags uint8

const (
	Read    Flags = 1 << iota // 1
	Write                     // 2
	Execute                   // 4
)

const (
	All Flags = Read | Write | Execute
)
```

- An 8-bit unsigned integer (`uint8`) is used to represent flags
- `iota` is used to automatically increment values
- Flags are defined using left shift, creating powers of 2:
  - `Read` = 00000001 $(2^0 = 1)$
  - `Write` = 00000010 $(2^1 = 2)$
  - `Execute` = 00000100 $(2^2 = 4)$

## Bitwise Operations

1. **Set Operation**: Combine flags

```go
func Set(a, b Flags) Flags {
	return a | b
}
```

2. **Clear Operation**: Remove specific flags

```go
func Clear(a, b Flags) Flags {
	return a &^ b
}
```

3. **Toggle Operation**: Flip specific flags

```go
func Toggle(a, b Flags) Flags {
	return a ^ b
}
```

4. **Check Operation**: Verify if any flag is set

```go
func Has(a, b Flags) bool {
	return a&b != 0
}
```

5. **Check All Operation**: Verify if all flags are set

```go
func HasAll(a, b Flags) bool {
	return a&b == b
}
```

## Usage

Sample usage:

```go
func main() {
	perms := Read | Write
	fmt.Println("has read:", Has(perms, Read))       // true
	fmt.Println("has execute:", Has(perms, Execute)) // false
	fmt.Println("has any flag:", Has(perms, All))    // true

	perms = Set(perms, Execute)
	perms = Clear(perms, Write)

	fmt.Println("has read and write:", HasAll(perms, Read|Write))     // false
	fmt.Println("has read and execute:", HasAll(perms, Execute|Read)) // true

	perms = Toggle(perms, Execute)
	fmt.Println("has execute:", Has(perms, Execute)) // false
}
```
