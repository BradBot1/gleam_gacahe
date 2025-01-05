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

// Some helper functions to reduce code duplication
import gacache
import gleam/dynamic
import gleam/list
import gleam/set
import gleeunit/should

// Sets up our cache with the appropriate key types
pub fn setup(callback) -> Nil {
  use keys <- repeat_for_key_types()
  let key_value_pairs = generate_values_for_keys(keys)
  use cache <- do_with_cache()
  set_all(cache, key_value_pairs)
  callback(cache, key_value_pairs)
}

pub fn do_with_cache(cache_handler) -> Nil {
  let cache = gacache.start() |> should.be_ok()
  cache |> cache_handler
  cache |> gacache.stop()
}

pub fn repeat_for_key_types(
  keys_handler: fn(List(dynamic.Dynamic)) -> Nil,
) -> Nil {
  string_keys() |> list.map(dynamic.from) |> keys_handler
  int_keys() |> list.map(dynamic.from) |> keys_handler
  custom_type_keys() |> list.map(dynamic.from) |> keys_handler
}

pub fn key_value_pairs_to_keys(key_value_pairs: List(#(ke, val))) -> List(ke) {
  key_value_pairs
  |> list.map(fn(tuple) {
    let #(first, _) = tuple
    first
  })
}

// Ensures that the cache is in the correct state as specified by the key value pairs
pub fn is_of_state(
  cache: gacache.Cache(ke, val),
  key_value_pairs: List(#(ke, val)),
) -> Nil {
  key_value_pairs |> key_value_pairs_to_keys() |> only_has_keys(cache, _)
  key_value_pairs |> keys_match_values(cache, _)
}

pub fn only_has_keys(cache: gacache.Cache(ke, val), keys: List(ke)) -> Nil {
  keys
  |> set.from_list()
  |> should.equal(cache |> gacache.keys() |> set.from_list())
}

pub fn keys_match_values(
  cache: gacache.Cache(ke, val),
  key_value_pairs: List(#(ke, val)),
) -> Nil {
  key_value_pairs
  |> list.each(fn(tuple) {
    let #(key, value) = tuple
    cache |> gacache.get(key) |> should.be_ok() |> should.equal(value)
  })
}

pub fn generate_values_for_keys(keys: List(ke)) -> List(#(ke, Int)) {
  keys |> list.length() |> list.range(0) |> list.zip(keys, _)
}

fn set_all(cache: gacache.Cache(ke, val), to_add: List(#(ke, val))) -> Nil {
  to_add
  |> list.each(fn(tuple) {
    let #(key, value) = tuple
    cache |> gacache.set(key, value)
  })
}

fn string_keys() -> List(String) {
  [
    "apples", "bananas", "oranges", "grapes", "lemons", "limes", "mangos",
    "melons", "pears", "pineapples", "plums", "strawberries", "tangerines",
    "watermelons",
  ]
}

fn int_keys() -> List(Int) {
  list.range(1, 5000)
}

// Just a type used to test that keys work as intended
type CacheKey {
  KeyOne
  KeyTwo(data: Int)
  KeyThree
  KeyFour(data: String)
}

fn custom_type_keys() -> List(CacheKey) {
  [
    KeyOne,
    KeyTwo(data: 1),
    KeyTwo(data: 2),
    KeyTwo(data: 3),
    KeyTwo(data: 4),
    KeyTwo(data: 5),
    KeyThree,
    KeyFour(data: "abc"),
    KeyFour(data: "test"),
    KeyFour(data: "123"),
    KeyFour(data: "Hello World!"),
  ]
}
