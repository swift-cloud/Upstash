# Upstash

A [Upstash](https://upstash.com) library compatible with all Apple platforms, Swift Cloud and Fastly Compute@Edge

## Usage

### Create a Client

```swift
let client = RedisClient(hostname: "my-host-12345.upstash.io", token: "...")
```

### GET

```swift
let visits = try await client.get("visits").decode(Int.self)
```

### SET

```swift
try await client.set("visits", 10)
```

### EXEC

```swift
let visits = try await client.exec("incr", "visits").decode(Int.self)
```
