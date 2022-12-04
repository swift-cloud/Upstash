# Upstash

A [Upstash](https://upstash.com) library compatible with all Apple platforms, Swift Cloud and Fastly Compute@Edge

## Usage

```swift
let client = RedisClient(hostname: "my-host-12345.upstash.io", token: "...")

let val: Int = try await client.get("foo")
```
