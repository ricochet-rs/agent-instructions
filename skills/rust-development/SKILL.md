---
name: rust-development
description: Apply ricochet-rs Rust design, implementation, formatting, linting, and workspace validation conventions when changing Rust source, Cargo manifests, SQLx queries, or Rust tests.
---

# Rust development

Use enums for finite value sets.
Use associated methods for behavior owned by a type.
Inline helpers used only once or twice.
Do not use boolean parameters, trait objects, or `serde_json::Value` fields.
Do not pass a receiver data it already owns.

Never call `.unwrap()` on `Option` or `Result`.
Use `crate::` paths instead of `super::`, except that test modules may use `super::*`.
Inline variables in format strings.
Use `tokio::fs` for asynchronous application I/O.
Use UTC timestamps.

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
