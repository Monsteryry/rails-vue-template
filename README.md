# Rails + Vue template

A starter for full-stack apps: a **Rails 8.1 API** backed by **PostgreSQL** with **UUID primary keys**, **Sidekiq + Redis** for background jobs, caching and Action Cable, and a **Vue 3 + Vite + TypeScript** frontend.

```
backend/        Rails API (Ruby 3.3, PostgreSQL, Sidekiq + Redis, RSpec)
frontend/       Vue 3, Vue Router, Pinia, Vitest, ESLint + Oxlint + Prettier
.devcontainer/  Docker dev environment (Ruby + Node), used by your editor and bin/docker
bin/setup       installs dependencies and prepares the database
bin/dev         runs Rails, Sidekiq and Vite
bin/docker      runs the dev container stack without an editor
docker-dev/     one container per process (web, sidekiq, frontend) for terminal debugging
```

Coding agents (Claude Code, Codex, Cursor, Copilot, ...) get project conventions from [AGENTS.md](AGENTS.md); `CLAUDE.md` imports it for Claude Code. Add your project's own rules at the bottom of `AGENTS.md`.

## Getting started

There are three ways to run the app: A and B need only Docker, C runs Ruby and Node on your machine. All of them use the same `bin/setup`.

### Option A: Dev Container (recommended, same on macOS, Windows and Linux)

Everything runs in Docker: Ruby, Node, Postgres and Redis. Gems and `node_modules` live in Docker volumes, so macOS, Windows and Linux binaries never mix when you switch machines.

You need only:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (on Windows, with the WSL 2 backend)
- Git
- An editor with Dev Containers support: VS Code or Cursor with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension, or JetBrains (RubyMine / WebStorm via *Remote Development → Dev Containers*). Optional; see "Without an editor" below.

Steps:

1. Clone the repo and open the folder in your editor.
2. Run **Dev Containers: Reopen in Container**. The first build takes a few minutes. After that, `bin/setup` runs automatically and the Ruby LSP, Vue, ESLint, Oxlint and Prettier extensions are installed in the container.
3. In the editor's terminal, which runs inside the container, start the app with `bin/dev`.
4. Open http://localhost:5173.

Every command (`bundle exec rspec`, `bin/rails console`, `npm run lint`, ...) runs in that terminal, just as it would natively.

**Without an editor**, `bin/docker` drives the same containers:

```bash
bin/docker up                                   # build, run bin/setup, then bin/dev (Ctrl+C stops)
bin/docker exec app bundle exec rspec           # commands run in backend/
bin/docker exec app bin/rails console
bin/docker exec -w /workspace/frontend app npx vitest run
bin/docker down                                 # stop (data stays in Docker volumes)
```

**Ports:** the container publishes Rails on 3000 and Vite on 5173. If something on your machine already uses them, create a `.env` file in the repo root (see `.env.example`), e.g. `RAILS_PORT=3100` and `VITE_PORT=5180`. Postgres and Redis are only reachable inside Docker, so they never clash with local installs.

**Windows tips:**

- Clone the repo *inside WSL* (e.g. `~/code` in Ubuntu), not under `C:\`. File access from Docker to Windows drives is slow, and file watching (live reload) is unreliable there. In WSL, run `code .` and reopen in the container.
- `.gitattributes` forces LF line endings, so the scripts still run in Linux containers even if Git on Windows is set to convert line endings.

### Option B: docker-dev (one container per process)

`docker-dev/docker-compose.yml` runs the same image as separate `web`, `sidekiq` and `frontend` services, next to `db` and `redis`. A one-shot `setup` service runs `bin/setup` first. Use it when you want each process in its own container with its own logs, or when you want `binding.break` to stop in a terminal you can type into.

```bash
cd docker-dev
cp .env.example .env              # optional: project name and host ports
docker compose up -d              # first run builds the image and runs bin/setup
docker compose logs -f web        # follow a service's output
docker compose exec web bundle exec rspec
docker compose exec web bin/rails console
docker compose down               # stop (data stays in Docker volumes)
```

**Debugging:** `web` and `sidekiq` run attached to a terminal. Put `binding.break` (or `debugger`) in the code, trigger it, then run:

```bash
docker compose attach web         # or: docker compose attach sidekiq
```

You get the `(rdbg)` prompt: `p some_var`, `next`, `step`, `info`, and `c` to continue. Detach with **Ctrl+P Ctrl+Q**; pressing Ctrl+C would stop the container.

Settings the app reads at runtime, such as API keys, go in `docker-dev/app.env` (copy `app.env.example`; it's git-ignored and passed to every service). Containers, volumes and the database are separate from Option A's, so run one stack at a time if they use the same host ports.

### Option C: Native

Requirements:

- Ruby 3.3 (see `backend/.ruby-version`)
- Node 24 (see `frontend/.nvmrc`; Node 22.22+ also works)
- Docker, for the local PostgreSQL and Redis containers (or your own PostgreSQL 13+ and Redis; the containers use PostgreSQL 18)
- On macOS, `libpq` to build the `pg` gem: `brew install libpq && bundle config build.pg --with-pg-config=$(brew --prefix libpq)/bin/pg_config`

```bash
bin/setup
bin/dev
```

If the ports are taken, run `RAILS_PORT=3100 VITE_PORT=5180 bin/dev`. If you already run Redis locally on 6379, either use it (no change needed) or start the container on another port with `REDIS_PORT=6380 REDIS_URL=redis://localhost:6380/0 bin/dev`.

### URLs

- Frontend: http://localhost:5173
- API: http://localhost:3000/api/health
- Sidekiq dashboard (development only): http://localhost:3000/sidekiq, with **Cron** and **Statuses** tabs

Vite proxies `/api/*` to Rails, so the browser talks to one origin and no CORS setup is needed in development. Database settings come from `DATABASE_*` env vars and Redis from `REDIS_URL`; the defaults match `docker-compose.yml`, and the dev container sets them for its own network.

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

## Background jobs, cache and Action Cable

Redis backs all three:

- **Active Job → Sidekiq** (`config.active_job.queue_adapter = :sidekiq` in `config/application.rb`). Queues and concurrency live in `config/sidekiq.yml`; `bin/dev` runs a Sidekiq process. Try it with `ExampleJob.perform_later("hello")` from `bin/rails console`. Specs use the in-memory `:test` adapter.
- **Rails.cache → Redis** in production (`config/environments/production.rb`). Development keeps the in-memory store; toggle caching with `bin/rails dev:cache`.
- **Action Cable → Redis** in development and production (`config/cable.yml`), so broadcasts from jobs reach connected clients.

- **Recurring jobs → [sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron).** Define them in `config/schedule.yml`; Sidekiq loads the file on start. The sample entry runs `ExampleJob` daily at 03:00.
- **Job status → [sidekiq-status](https://github.com/kenaniah/sidekiq-status).** `ApplicationJob` includes `Sidekiq::Status::Worker`, so every job's status is kept in Redis for 30 minutes (set in `config/initializers/sidekiq.rb`). Report progress with `total` / `at`, and read it with `Sidekiq::Status.status(job.provider_job_id)` or `Sidekiq::Status.pct_complete(...)`.

## Tests and linting

```bash
cd backend && bundle exec rspec && bin/rubocop && bin/brakeman
cd frontend && npm run lint && npm run build && npx vitest run
```

Backend tests use **RSpec** (`backend/spec`) with:

- [FactoryBot](https://github.com/thoughtbot/factory_bot_rails): put factories in `spec/factories`, then call `create(:user)` / `build(:user)`.
- [shoulda-matchers](https://matchers.shoulda.io/): `it { is_expected.to validate_presence_of(:name) }`, `belong_to(:project)`, ...
- [Faker](https://github.com/faker-ruby/faker) for fake data in factories.
- [SimpleCov](https://github.com/simplecov-ruby/simplecov): every `rspec` run writes `backend/coverage/index.html` (line and branch coverage). CI uploads it as the `coverage` artifact.
- Active Job matchers (`have_enqueued_job`) and cleanup between examples, from `spec/support/`.

`rails g model` / `rails g job` generate specs and factories automatically. Specs run in random order; reproduce a failure with `rspec --seed <seed>`, or re-run only failures with `rspec --only-failures`.

RuboCop uses its defaults plus the `rubocop-rails`, `rubocop-performance`, `rubocop-rspec`, `rubocop-rspec_rails` and `rubocop-factory_bot` plugins, with a few Rails-friendly overrides in `backend/.rubocop.yml` (double quotes, 120-char lines, no class doc comments). Run `bin/rubocop -A` to autocorrect, for example to add the `# frozen_string_literal: true` comment to newly generated files.

GitHub Actions (`.github/workflows/ci.yml`) runs all of these on every push and PR.

## Starting a new project from this template

1. Click **Use this template** on GitHub (enable it under the repo's *Settings → Template repository*), or clone and re-init git.
2. Rename the app: change `module Backend` in `backend/config/application.rb`, the `app_*` database names in `backend/config/database.yml`, and the default `COMPOSE_PROJECT_NAME` in `docker-dev/docker-compose.yml` and `docker-dev/.env.example`, so two projects never share containers or volumes.
3. Create credentials for the new app: `cd backend && bin/rails credentials:edit` (this generates `config/master.key`, which is git-ignored). Alternatively, set `SECRET_KEY_BASE` in production.
4. Remove the sample health check (`backend/app/controllers/api/health_controller.rb`, `frontend/src/views/HomeView.vue`) once you have real endpoints.

## Production

`backend/Dockerfile` builds the Rails API. Set `DATABASE_URL`, `REDIS_URL`, and `SECRET_KEY_BASE` or `RAILS_MASTER_KEY`. Run the same image a second time as the worker with `bundle exec sidekiq`. Protect `/sidekiq` with authentication before mounting it outside development. `npm run build` in `frontend/` produces static files in `frontend/dist` to host on any static host or CDN, with `/api` routed to the Rails service.
