# AGENTS.md

Guidance for coding agents working in this repo. Rails 8.1 API (`backend/`) and Vue 3 + Vite + TypeScript (`frontend/`), with PostgreSQL, Redis and Sidekiq. Projects created from this template should add their own domain rules at the bottom.

## Where commands run

- **Development runs in the dev container** (`.devcontainer/`). In the editor's container terminal, run commands as usual. From the host, prefix them with `bin/docker exec app`, which starts in `backend/`:
  - `bin/docker exec app bundle exec rspec`
  - `bin/docker exec -w /workspace/frontend app npx vitest run`
- A native setup (Ruby and Node on the host) also works; see README.md. Don't install Ruby, Node, gems or packages on the host unless asked.
- Backend commands run in `backend/`, frontend commands in `frontend/`. The repo root has no Gemfile or package.json.
- `bin/setup` installs dependencies and prepares the database (safe to re-run). `bin/dev` runs Rails (:3000), Sidekiq and Vite (:5173).

## Before you say you're done

Run what CI runs (`.github/workflows/ci.yml`) for the side you changed, and fix failures rather than skipping them:

```bash
# backend/
bundle exec rspec
bin/rubocop
bin/brakeman --no-pager --exit-on-warn --exit-on-error

# frontend/
npm run lint
npm run build      # includes vue-tsc type-check
npx vitest run
```

## Backend conventions

- **UUID primary keys everywhere.** Generators handle it (`config/application.rb`). In hand-written migrations use `create_table :things, id: :uuid` and `t.references :project, type: :uuid, foreign_key: true`. Order by `created_at`, never by `id`.
- **API only, under `/api`.** Add routes inside `namespace :api` in `config/routes.rb`, with controllers in `app/controllers/api/` that render JSON.
- **Tests use RSpec**, not Minitest (`spec/`; there is no `test/`). Use request specs for endpoints (`spec/requests/`). Factories go in `spec/factories` (FactoryBot plus Faker), validations and associations are checked with shoulda-matchers, and job specs use `have_enqueued_job`.
- **After `rails g …` or new files**, run `bin/rubocop -A`. Generated code uses single quotes and lacks `# frozen_string_literal: true`, which RuboCop flags.
- **Background jobs**: inherit from `ApplicationJob`, which runs on Sidekiq and includes sidekiq-status, so `total` / `at` report progress. Recurring jobs go in `config/schedule.yml` (sidekiq-cron). Queues are in `config/sidekiq.yml`.
- Redis backs Sidekiq, `Rails.cache` (production) and Action Cable. Don't reintroduce Solid Queue, Solid Cache or Solid Cable.
- Configuration comes from env vars (`DATABASE_*`, `REDIS_URL`, `SECRET_KEY_BASE`); don't hardcode hosts or credentials.

## Frontend conventions

- Call the API through `src/api/client.ts` (`apiFetch`) with relative `/api/...` paths. Vite proxies them to Rails, so no CORS or absolute URLs.
- Vue 3 `<script setup lang="ts">`, Vue Router in `src/router`, Pinia stores in `src/stores`, the `@/` alias for `src/`.
- Unit tests live next to components in `__tests__/*.spec.ts` (Vitest + Vue Test Utils).
- Prettier and ESLint/Oxlint decide formatting; run `npm run format` rather than hand-formatting.

## Don't

- Edit `db/schema.rb` by hand; write a migration and run `bin/rails db:migrate`.
- Commit secrets: `config/master.key`, `.env`, credentials or tokens.
- Run `npm install` on the host while working in the container. `node_modules` and gems live in Docker volumes so macOS, Windows and Linux binaries never mix.
- Change `.gitattributes` or commit CRLF line endings; the scripts must run in Linux containers.
- Mount `/sidekiq` outside development without adding authentication.
- Add gems or npm packages without saying why; prefer what's already in the stack.

## Map

```
backend/app/controllers/api/   JSON endpoints
backend/app/jobs/               Active Job classes (Sidekiq)
backend/config/                 sidekiq.yml, schedule.yml, cable.yml, database.yml, initializers/sidekiq.rb
backend/spec/                   RSpec; support/ holds FactoryBot, shoulda-matchers, Active Job setup
frontend/src/                   api/, views/, components/, router/, stores/
.devcontainer/                  dev image, compose override, editor settings
bin/                            setup, dev, docker
.env (git-ignored)              host ports for the dev container; see .env.example
```

## Project-specific notes

<!-- Projects created from this template: add domain rules, glossary and decisions here. -->
