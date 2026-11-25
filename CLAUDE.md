# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Taolao is a Rails 8.1 app (generated from the Le Wagon rails-templates) for practicing Japanese at real places: users browse nearby places on a map, start a "visit" to a place, prepare/converse (messages), and collect phrases (English / Japanese / romaji). Many controller actions (`MessagesController#create`, `VisitsController#show/update`, `visits#review`) are still stubs — routes exist ahead of implementation.

## Commands

```bash
bin/setup                      # install gems, prepare DB
bin/dev                        # run server (just `rails server`; no JS/CSS build step)
bin/rails db:create db:migrate db:seed
bin/rails db:seed:replant      # wipe and reseed (seeds destroy all records first)

bin/rails test                                     # all tests (Minitest)
bin/rails test test/models/place_test.rb           # one file
bin/rails test test/models/place_test.rb:12        # one test by line

bin/rubocop                    # lint (config in .rubocop.yml; test/, db/, config/ excluded; max line 120)
bin/brakeman                   # security scan
bin/ci                         # full CI pipeline defined in config/ci.rb
```

Requires a local PostgreSQL (`taolao_development` / `taolao_test`).

## Architecture

- **Data model** (`db/schema.rb`): `User` (Devise, has `level`) → `Visit` (belongs to user + place; `status` enum `active/ready/completed`; `prep` jsonb; `self_rating`) → `Message` (`role`, `content` — chat-style log) and `Phrase`. `Place` has `lat`/`long` (note: column is `long`, not `lng`), `minimum_level`, `image_url`.
- **Auth**: `ApplicationController` enforces `authenticate_user!` globally; public pages must `skip_before_action` (see `PagesController`).
- **Maps / geolocation flow**: `places#index` → `app/javascript/controllers/google_maps_controller.js` (Stimulus, uses the `gmaps` importmap pin). On connect it asks the browser for geolocation and reloads the page with `?user_lat=&user_lng=`; the controller then filters places with Geocoder's `.near(..., 5, units: :km)` and passes markers (with `info_window_html` rendered from `places/_map_box`) via a `data-google-maps-markers-value` attribute. Default center is Tokyo Station.
- **Google APIs**: two env vars loaded via dotenv from `.env` — `API_KEY` (server-side Geocoder lookups, `config/initializers/geocoder.rb`) and `GOOGLE_API_BROWSER_KEY` (Maps JS script tag in `layouts/application.html.erb`).
- **Frontend**: importmap (no Node/bundler), Turbo + Stimulus, Bootstrap 5 + Font Awesome via Sprockets/SassC. Styles are organized as `app/assets/stylesheets/{config,components,pages}/` with `_index.scss` files that must import each new partial. Forms use SimpleForm (Bootstrap config).
- **XP / levelling**: XP is earned only from real-world activity, never in-app practice. Rules and constants live in `User` (level curve, cap 100), `Visit#complete_review!` (visit + used-phrase XP) and `Phrase#memorize!` (memorize bonus, only for phrases used or heard on a visit, paid once).
- **Post-visit review** (`visits#review`, one page): rating form (becomes the XP card once submitted), AI-suggested staff phrases (`StaffPhraseSuggester`, lazy Turbo Frame from `visits#phrase_suggestions`, cached per place; "Add" → `PhrasesController#create`), and the "what did you hear?" chat (`ReviewMessagesController` → `PhraseFinderChat`, which gives the AI `RecordPhraseTool` to save a phrase once it's confident). Heard phrases are `source: :heard` phrases on the visit: private to the user, and their study list (`status` learning/memorized). `places/show` lists only `prepped` phrases for that reason.
- **AI (ruby_llm, OpenAI)**: configured in `config/initializers/ruby_llm.rb`; the key is `OPENAI_API_KEY`, falling back to `API_KEY` (which Geocoder also reads as a Google key, though it makes no API calls today). Chats use `Message` with `purpose` (`prep`/`review`) so each chat only replays its own history. `MessagesController` is left for the Prep stage. Tests never call OpenAI: include `RubyLLM::TestHelper` and use `stub_replies` / `tool_call`; the test env gets a dummy key.
- **Infra**: Solid Cache/Queue/Cable (DB-backed), Kamal deploy config in `config/deploy.yml`.

## Ruby 3.3.5 constraint

Ruby is pinned at 3.3.5 and can't be upgraded, but it is affected by the Nov 2026 Regexp/String advisory (heap overflows in string case conversion and in regexp compilation/matching with attacker-controlled patterns). The Brakeman warning is accepted in `config/brakeman.ignore`. In new code:
- Never call `downcase`/`upcase`/`capitalize`/`swapcase`/`casecmp`/`parameterize` etc. on user-supplied or LLM-generated text (phrases, messages, params). Compare text exactly.
- Never build a Regexp from user or LLM input (`Regexp.new`, `/#{...}/`), and don't call `Regexp#to_s` on such patterns.
- `ApplicationController#reject_non_ascii_email` keeps non-ASCII emails away from Devise's email downcasing; keep it in place.
