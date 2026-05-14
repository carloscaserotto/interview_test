# Book Management — Code Challenge

Rails 8.1 / Ruby 3.x / PostgreSQL.

## Setup

```bash
bundle install
bin/rails db:create db:migrate
bin/rails test
bin/rails server
```

## Endpoints

| Verb | Path                  | Description                                  |
|------|-----------------------|----------------------------------------------|
| GET  | `/books`              | Paginated list. Filters: `status`, `q`.      |
| GET  | `/books/:id`          | Book detail with its reservations.           |
| POST | `/books/:id/reserve`  | Reserve an available book (body: `{ reservation: { email } }`). |

### `GET /books`

Query params:

- `status` — `available` / `reserved` / `loaned`
- `q` — case-insensitive title search
- `page` — defaults to `1`
- `per_page` — defaults to `25`, capped at `100`

Response headers: `X-Total-Count`, `X-Page`, `X-Per-Page`, `X-Total-Pages`. Responses are ETag-cached, so repeat requests return `304 Not Modified` when nothing changed.

### `POST /books/:id/reserve`

Body:

```json
{ "reservation": { "email": "user@example.com" } }
```

Returns `201` with the reservation, `422` if the book is not available, `404` if the book does not exist.

## Task 1 — Reservations

- `POST /books/:id/reserve` is handled by `ReserveBook` service.
- The book row is locked inside a transaction (`@book.lock!`) so two concurrent reservation attempts cannot both succeed.
- Status transitions to `reserved` only after the reservation row is persisted.
- Edge cases covered in tests: already reserved, loaned, missing book.

## Task 2 — GET endpoints optimization

The `index` and `show` actions did not exist; they were implemented with the following optimizations:

1. **Avoiding N+1**
   - `reservations_count` counter cache on `books` — listing N books no longer fires N count queries.
   - `show` uses `includes(:reservations)` to load reservations in a single extra query.
2. **Database indexes** (`AddIndexesAndCounterCache` migration)
   - `books(status)` — used by `?status=` filter and by the enum scopes.
   - `books(title)` — supports prefix/title search.
   - `reservations(email)` — for lookups by user.
   - `reservations(book_id, created_at)` — supports listing a book's reservations chronologically without a sort.
3. **Pagination** — `index` always paginates with a hard cap (`per_page <= 100`) to bound memory and DB work regardless of dataset size.
4. **Column selection** — `index` selects only the columns it actually serializes, avoiding the cost of pulling timestamps and other unused fields off disk.
5. **HTTP caching** — both `index` and `show` use `stale?` so well-behaved clients get `304 Not Modified` instead of a fresh payload + serialization.
6. **Lightweight serialization** — explicit `serialize_book` keeps the payload predictable and avoids the overhead of `to_json` walking every attribute / association.

### Trade-offs / next steps

- Counter caches can drift; if it becomes a concern, a periodic reconciliation job (or `Book.reset_counters`) keeps it honest.
- For very large tables, `LIMIT/OFFSET` pagination becomes expensive on deep pages — keyset/cursor pagination (`WHERE id > ?`) is the next step.
- Reservations are returned inline on `show` for simplicity. For books with many reservations, a dedicated `GET /books/:id/reservations` paginated endpoint would be cleaner.
- For read-heavy traffic, putting Russian-doll fragment caching (or a Rails low-level cache around the serialized payload) on top of the ETag would offload the DB further.
