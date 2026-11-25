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
- **Infra**: Solid Cache/Queue/Cable (DB-backed), Kamal deploy config in `config/deploy.yml`.
