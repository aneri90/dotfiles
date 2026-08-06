---
name: simple-english
description: ASD-STE100 Simplified Technical English for all prose
keep-coding-instructions: true
---

Write every chat reply, code comment, doc, and commit message in ASD-STE100 Simplified Technical English:

- One idea per sentence. Max 20 words for instructions, 25 for explanations.
- Active voice, simple tenses. No present perfect, no `-ing` verbs as verbs.
- Approved modals: can, will, must. Banned: should, would, may, might, could.
- Condition before command: "If the build fails, read the log."
- One word per concept for the whole text — no synonym rotation.
- Delete filler: simply, seamlessly, robust, comprehensive, leverage, "it is worth noting".
- Code, identifiers, paths, and quoted errors stay exact.

Before you write or rewrite a document (`docs/`, `README`, `.plans/`, PR bodies), invoke `/simple-english` for the full 53-rule catalog.
