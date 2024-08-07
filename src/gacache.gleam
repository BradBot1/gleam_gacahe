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
import gleam/dict
import gleam/erlang/process
import gleam/otp/actor
import gleam/result

type Key =
  String

type Store(value) =
  dict.Dict(Key, value)

type Cache(value) =
  process.Subject(Action(value))

pub type Error {
  /// Provided when the Get Action is sent with a Key that has no corresponding Value
  NotCached
  /// Provided when either a Get or Raw Action cannot be completed in 10 seconds
  Timeout
}

/// Actions are passed to the Cache to interact with it's Store
pub type Action(value) {
  Set(key: Key, value: value)
  Get(ret: process.Subject(Result(value, Error)), key: Key)
  Clear(key: Key)
  Keys(ret: process.Subject(List(Key)))
  Reset
  Raw(ret: process.Subject(Store(value)))
  Merge(store: Store(value))
  Stop
}

/// Start the cache
pub fn start() -> Result(Cache(value), actor.StartError) {
  actor.start(dict.new(), process_action)
}

/// Internal handling for Actions
/// Performs Actions on the Store
fn process_action(action: Action(value), store: Store(value)) {
  case action {
    Set(key, value) -> dict.insert(store, key, value) |> actor.continue
    Get(ret, key) -> {
      process.send(ret, dict.get(store, key) |> result.replace_error(NotCached))
      actor.continue(store)
    }
    Clear(key) -> actor.continue(dict.delete(store, key))
    Keys(ret) -> {
      process.send(ret, dict.keys(store))
      actor.continue(store)
    }
    Reset -> actor.continue(dict.new())
    Raw(ret) -> {
      process.send(ret, store)
      actor.continue(store)
    }
    Merge(new_store) -> actor.continue(dict.merge(store, new_store))
    Stop -> actor.Stop(process.Normal)
  }
}

/// Updates the Store with key=value
pub fn set(cache: Cache(value), key: Key, value: value) {
  process.send(cache, Set(key, value))
}

pub fn get(cache: Cache(value), key: Key) -> Result(value, Error) {
  process.try_call(cache, Get(_, key), 10_000) |> result.unwrap(Error(Timeout))
}

/// Removes the Value associated with the provided Key from the Store
pub fn clear(cache: Cache(value), key: Key) {
  process.send(cache, Clear(key))
}

/// Returns all keys known by the Store
pub fn keys(cache: Cache(value)) -> List(Key) {
  process.try_call(cache, Keys(_), 10_000) |> result.unwrap([])
}

/// Clears the whole Store
pub fn reset(cache: Cache(value)) {
  process.send(cache, Reset)
}

/// Returns the Store, avoid if possible
pub fn raw(cache: Cache(value)) -> Result(Store(value), Error) {
  process.try_call(cache, Raw(_), 10_000) |> result.replace_error(Timeout)
}

/// Merges the Store with the provided Store using dict:merge/2
pub fn merge(cache: Cache(value), new_store: Store(value)) {
  process.send(cache, Merge(new_store))
}

/// Stops the cache
pub fn stop(cache: Cache(value)) {
  process.send(cache, Stop)
}
