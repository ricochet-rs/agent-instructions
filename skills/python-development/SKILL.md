---
name: python-development
description: Apply ricochet-rs Python import, typing, formatting, linting, and testing conventions when changing Python packages, scripts, configuration, or tests.
---

# Python development

Use absolute imports.
Do not use relative imports.
Add type hints to every function signature, including test functions.
Keep imports as the first content in Python files.
Do not place comments or docstrings above imports.

Use repository `just` commands when provided.
Run Ruff formatting and linting, then run the relevant test suite.
