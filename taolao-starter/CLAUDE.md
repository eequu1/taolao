# TAOLAO

An app that gets travellers learning Japanese out of the app and into real
conversations in Tokyo.

## Stages and owners
| Stage | Owner | Goal | Folders |
|---|---|---|---|
| Before | Annie | Get out the door | `app/controllers/before/`, `app/views/before/` |
| Prep | Yoshi | Feel ready | `app/controllers/prep/`, `app/views/prep/` |
| At the place | Paul | The right help in the moment | `app/controllers/at_place/`, `app/views/at_place/` |
| After | Jonny | Want to go again | `app/controllers/after/`, `app/views/after/` |

Stay inside your stage's folders. Ask before changing shared files:
models, `config/routes.rb`, `db/schema.rb`, layouts.

## What connects the stages
A `Visit` belongs to a `User` and a `Place`. Before creates it; every other
stage adds its own tables that point to a Visit.

## Stack
Le Wagon Rails (Devise template): Postgres, Bootstrap, simple_form,
Stimulus/Turbo. No React. No new gems without asking the team.

## How to work with me (Claude)
- Before building, I need the story:
  "As a traveller, I can…" and "I'll know it works when…".
  If either is missing, ask for it instead of guessing.
- Plan first for anything bigger than one small step. Wait for approval.
- Write the tests first, then make them pass. Never change a test to make it pass.
- One small step at a time. Say when it's a good moment to commit.
- Explain code as if to a new teammate who knows bootcamp Rails.
  Keep code simple, with short comments saying *why*.

## Rules
- Café workers are "staff", never "host".
- Never commit `.env`, API keys, or real people's names (seeds, tests, commits).
- Prototypes live outside this app. Only the lesson goes in `prototypes.md`.
