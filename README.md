# Rails + Vue template

A starter for full-stack apps: a **Rails 8.1 API** backed by **PostgreSQL** with **UUID primary keys**, and a **Vue 3 + Vite + TypeScript** frontend.

```
backend/    Rails API (Ruby 3.3, PostgreSQL, Solid Cache/Queue/Cable)
frontend/   Vue 3, Vue Router, Pinia, Vitest, ESLint + Oxlint + Prettier
bin/setup   one-time setup
bin/dev     runs both apps
```

## Requirements

- Ruby 3.3 (see `backend/.ruby-version`)
- Node 24 (see `frontend/.nvmrc`; Node 20.19+ also works)
- Docker, for the local PostgreSQL container (or your own PostgreSQL 13+)
- On macOS, `libpq` to build the `pg` gem: `brew install libpq && bundle config build.pg --with-pg-config=$(brew --prefix libpq)/bin/pg_config`

## Getting started

```bash
bin/setup
bin/dev
```

- Frontend: http://localhost:5173
- API: http://localhost:3000/api/health

Vite proxies `/api/*` to Rails, so the browser talks to one origin and no CORS setup is needed in development. If the ports are taken, run `RAILS_PORT=3100 VITE_PORT=5180 bin/dev`.

Database settings come from `DATABASE_*` env vars (see `.env.example`); the defaults match `docker-compose.yml`.

## UUID primary keys

Every table you generate gets a UUID primary key, and `references` columns are UUIDs too:

```bash
cd backend
bin/rails g model Project name:string
bin/rails g model Task project:references title:string
bin/rails db:migrate
```

```ruby
create_table "projects", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
# ...
create_table "tasks", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
  t.uuid "project_id", null: false
```

How it is wired:

- `config/application.rb` sets `g.orm :active_record, primary_key_type: :uuid` for generators.
- `ApplicationRecord` sets `implicit_order_column = "created_at"`, so `.first` / `.last` follow creation order instead of random UUID order.
- `db/migrate/*_enable_uuid_extensions.rb` enables `pgcrypto` (only needed on PostgreSQL < 13; `gen_random_uuid()` is built in from 13).

When writing a migration by hand, pass `id: :uuid` to `create_table` and `type: :uuid` to `references`.

## Tests and linting

```bash
cd backend && bin/rails test && bin/rubocop && bin/brakeman
cd frontend && npm run lint && npm run build && npx vitest run
```

GitHub Actions (`.github/workflows/ci.yml`) runs all of these on every push and PR.

## Starting a new project from this template

1. Click **Use this template** on GitHub (enable it under the repo's *Settings → Template repository*), or clone and re-init git.
2. Rename the app: change `module Backend` in `backend/config/application.rb` and the `app_*` database names in `backend/config/database.yml`.
3. Create credentials for the new app: `cd backend && bin/rails credentials:edit` (this generates `config/master.key`, which is git-ignored). Alternatively, set `SECRET_KEY_BASE` in production.
4. Remove the sample health check (`backend/app/controllers/api/health_controller.rb`, `frontend/src/views/HomeView.vue`) once you have real endpoints.

## Production

`backend/Dockerfile` builds the Rails API. Set `DATABASE_URL`, plus `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL` and `CABLE_DATABASE_URL` for the Solid Cache/Queue/Cable databases, and `SECRET_KEY_BASE` or `RAILS_MASTER_KEY`. `npm run build` in `frontend/` produces static files in `frontend/dist` to host on any static host or CDN, with `/api` routed to the Rails service.
