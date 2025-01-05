//  Copyright 2024 BradBot_1

//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at

//      http://www.apache.org/licenses/LICENSE-2.0

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
import gacache
import gacache_test/common
import gleam/dict
import gleam/list
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// Ensure that we can start and stop the cache
// and that stopping the cache actually stops the cache
pub fn start_stop_test() -> Nil {
  let cache = gacache.start() |> should.be_ok()
  gacache.stop(cache)
  // Once stopped we can't get values
  gacache.get(cache, "apples") |> should.be_error()
  Nil
}

// Ensure that we can set and get values
// and that the set value is correct
pub fn set_get_test() -> Nil {
  let cache =
    gacache.start()
    |> should.be_ok()
  cache |> gacache.set("apples", "oranges")
  cache |> gacache.get("apples") |> should.equal(Ok("oranges"))
  gacache.stop(cache)
  // Once stopped we can't get values
  gacache.get(cache, "apples") |> should.be_error()
  Nil
}

// Ensure that the keys function returns the correct keys
pub fn keys_test() -> Nil {
  use cache, key_value_pairs <- common.setup()
  cache |> common.keys_match_values(key_value_pairs)
}

// Ensure that the demo works as intended
// some minor modifications to make it more testy
pub fn demo_test() -> Nil {
  let cache = gacache.start() |> should.be_ok()
  gacache.set(cache, "test", "val")
  gacache.set(cache, "funky", "1")
  gacache.get(cache, "test") |> should.equal(Ok("val"))
  gacache.keys(cache) |> should.equal(["funky", "test"])
  gacache.stop(cache)
}

// Clears the first 5 values and then ensures that the keys and state it reflective
pub fn clear_get_test() -> Nil {
  use cache, key_value_pairs <- common.setup()
  let #(first, second) = key_value_pairs |> list.split(5)
  first
  |> list.each(fn(tuple) {
    let #(key, _) = tuple
    cache |> gacache.clear(key)
    cache |> gacache.get(key) |> should.be_error()
  })
  second
  |> list.each(fn(tuple) {
    let #(key, value) = tuple
    cache |> gacache.get(key) |> should.be_ok() |> should.equal(value)
  })
  cache |> common.only_has_keys(second |> common.key_value_pairs_to_keys())
  gacache.stop(cache)
}

// Ensures the cache is reset and the set value is no longer available
pub fn reset_test() -> Nil {
  use cache, key_value_pairs <- common.setup()
  cache |> gacache.reset()
  key_value_pairs
  |> list.each(fn(tuple) {
    let #(key, _) = tuple
    cache |> gacache.get(key) |> should.be_error()
  })
  gacache.stop(cache)
}

// Ensures that the cache will now contain the new key value pair
pub fn merge_test() -> Nil {
  use keys <- common.repeat_for_key_types()
  let key_value_pairs = common.generate_values_for_keys(keys)
  use cache <- common.do_with_cache()
  let #(first, second) = key_value_pairs |> list.split(5)
  first
  |> list.each(fn(tuple) {
    let #(key, value) = tuple
    cache |> gacache.set(key, value)
  })
  cache |> common.is_of_state(first)
  cache |> gacache.merge(second |> dict.from_list())
  cache |> common.is_of_state(key_value_pairs)
}

// Ensures that the cache will now contain the new key value pair 
// and overwrite the old key value pair
pub fn merge_overwrite_test() -> Nil {
  use keys <- common.repeat_for_key_types()
  let key_value_pairs = common.generate_values_for_keys(keys)
  use cache <- common.do_with_cache()
  let #(first, second) = key_value_pairs |> list.split(5)
  first
  |> list.each(fn(tuple) {
    let #(key, value) = tuple
    cache |> gacache.set(key, value)
  })
  cache |> common.is_of_state(first)
  let #(to_mutate, others) = second |> list.split(5)
  cache |> gacache.merge(to_mutate |> dict.from_list())
  cache |> common.is_of_state(first |> list.append(to_mutate))
  let mutated_combined =
    to_mutate
    |> list.map(fn(tuple) {
      let #(key, value) = tuple
      #(key, value * 2)
    })
    |> list.append(others)
  cache |> gacache.merge(mutated_combined |> dict.from_list())
  cache |> common.is_of_state(mutated_combined |> list.append(first))
}
