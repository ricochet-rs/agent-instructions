---
name: rust-development
description: Apply ricochet-rs Rust design, implementation, formatting, linting, and workspace validation conventions when changing Rust source, Cargo manifests, SQLx queries, or Rust tests.
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
