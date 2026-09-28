---
name: rust-development
description: Apply ricochet-rs Rust design, implementation, formatting, linting, and workspace validation conventions when changing Rust source, Cargo manifests, `.cargo/config.toml`, SQLx queries, Rust tests, or the scripts and container images that build Rust.
---

# Rust development

Design how new types connect to the existing domain model before implementing them.
Extend the structure already responsible for the behavior instead of adding a parallel abstraction.
Use enums rather than strings or integers for finite value sets so invalid states are unrepresentable.
Use associated methods for behavior owned by a type.
Use free functions only for behavior that belongs to no type.
Inline helpers used only once or twice.
Do not use boolean parameters.
Do not use trait objects such as `Arc<dyn Trait>` or `Box<dyn Trait>`.
Do not use `serde_json::Value` as a field type.
Model the data instead.
Do not pass a receiver data it already owns.
Use UTC timestamps.
Use `jiff::Timestamp::now()` instead of local or zoned current time.
Use timestamp serialization features instead of manual string formatting.
Name functions for their actions, not their return values.
Do not use `maybe_*` or `should_*` names.

Never call `.unwrap()` on `Option` or `Result`.
Use `crate::` paths instead of `super::`, except that test modules may use `super::*`.
Give an item the narrowest visibility that compiles, reserving `pub` for what another crate names and `pub(crate)` for what another module does.
Do not re-export with `pub use module::*`, which hides where an item is defined and publishes items that needed no visibility beyond their own module.
Inline variables in format strings.
Use `format!()` for user-facing strings containing placeholders.
Do not rely on lint detection when a placeholder names a field that is not in local scope.
Use `tokio::fs` for asynchronous application I/O.

## Tracing

Instrument methods that emit `info!` or `error!` with `#[tracing::instrument(skip(...))]`.
Use structured fields for identifiers, errors, and other queryable values.
Write lowercase event messages that describe the event rather than the function.
Use `info!` for healthy state changes and `debug!` for routine steps and timer ticks.
Report a failure at one layer only.
Do not combine `err` instrumentation with a handwritten log of the same error.
Callers may log a handled consequence at `debug!` without repeating the error payload.
Use `err(level = "warn")` on polled or client-driven error paths.
Do not use `err` for expected error variants that callers handle.
When renaming an instrumented argument into a field, skip the original argument.
Adding a differently named field does not suppress the automatically recorded argument.
Skip struct arguments that have been destructured into explicit span fields.
Give detached tasks their own named child span.
Do not instrument detached tasks with `tracing::Span::current()`.

Use compile-time checked SQLx macros.
Use `query_as!` or `query_scalar!` for returned rows and `query!` for statements without rows.
Model JSONB with `sqlx::types::Json<T>` without casting it.

Prefer repository `just` commands.
Run `just fmt` when available.
For a Cargo workspace, validate all crates and targets with:

```sh
cargo check --workspace --all-targets --all-features
```

Run repository tests and pattern checks required by its local instructions.
Leave one core free for the host when building or testing, because cargo and the test harnesses default to every core and a shared machine stops responding.
Export `CARGO_BUILD_JOBS=-1`, which cargo reads as the core count minus one, and pass `--test-threads=$(($(nproc) - 1))` to libtest and nextest, since libtest rejects a negative count.

## Build configuration

Keep rustflags that every target needs in a `[target.'cfg(...)']` table of `.cargo/config.toml`.
Cargo joins `cfg` tables with each other and with `CARGO_TARGET_<TRIPLE>_RUSTFLAGS`, but a `[build]` list and a `[target.<triple>]` list replace one another.
Never export `RUSTFLAGS` from a script or pipeline step, because it replaces every configured list and silently drops a required flag from that build.
Pass an extra flag for one target through `CARGO_TARGET_<TRIPLE>_RUSTFLAGS` instead.
When code compiles differently without a configured `--cfg` and separately built artifacts must agree on it, fail the build with `#[cfg(not(<flag>))] compile_error!` rather than detecting the disagreement at runtime.
Include `.cargo/config.toml` in every container build context, ignoring the rest of `.cargo/` with `.cargo/*` and `!.cargo/config.toml` rather than the whole directory.
A `linker` set in `.cargo/config.toml` also becomes the prefix `cc-rs` uses to find C and C++ compilers, so a build image that provides `<prefix>-gcc` must also provide `<prefix>-g++`.
