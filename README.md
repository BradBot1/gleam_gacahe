# gacache

[![Package Version](https://img.shields.io/hexpm/v/gacache)](https://hex.pm/packages/gacache)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gacache/)

```sh
gleam add gacache@1
```
```gleam
import gacache
import gleam/io

pub fn main() {
  // Start a cache
  let assert Ok(cache) = gacache.start() // Starts the cache
  gacache.set(cache, "test", "val") // Set a value
  gacache.set(cache, "funky", "1") // Set a value
  let _ = io.debug(gacache.get(cache, "test"))// Ok("val") | The value bound to the key
  io.debug(gacache.keys(cache)) // ["funky", "test"] | All keys in the map
  gacache.stop(cache) // Stops the cache
}
```

Further documentation can be found at <https://hexdocs.pm/gacache>.
