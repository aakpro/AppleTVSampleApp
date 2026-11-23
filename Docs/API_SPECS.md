# API specification (TMDB v3)

The HTTP contract between `SampleTVAPI` and TMDB. Implementation code is in
[Phase 3](Phase03_API_Layer/Documentation/Phase_03_API_Layer.md). Verify details against the official
docs (<https://developer.themoviedb.org/reference>) when TMDB changes something.

## Configuration

| Item | Value |
|------|-------|
| Base URL | `https://api.themoviedb.org/3` |
| Image base URL | `https://image.tmdb.org/t/p/<size><path>` |
| Auth | `Authorization: Bearer <API Read Access Token>` header. The token is **not** the short v3 `api_key`. |
| Format | `Accept: application/json` |
| Language | `language=en-US` on every request (configurable in `TMDBConfiguration`) |
| Adult content | `include_adult=false` on `discover` and `search` |
| Timeout | 30 s per request |

The token is supplied at build time through `Config/Secrets.xcconfig` → Info.plist key `TMDBReadAccessToken`
(see [Phase 1](Phase01_Foundation/Documentation/Phase_01_Foundation.md)). It is embedded in the app bundle, so
treat it as low-value: acceptable for a sample, not for a shipping product (use a backend proxy there).
Never put the token in a URL; URLs end up in logs and caches.

All endpoints below are **GET**. (Earlier drafts of these docs listed POST and a `/recommendation` endpoint;
neither exists.)

## Endpoints used

| Purpose | Endpoint | Parameters |
|---------|----------|-----------|
| Browse / filter TV | `/discover/tv` | `page`, `sort_by`, `with_genres`, `first_air_date.gte`, `first_air_date.lte`, `vote_average.gte`, `vote_count.gte` |
| Browse / filter movies | `/discover/movie` | `page`, `sort_by`, `with_genres`, `primary_release_date.gte`, `primary_release_date.lte`, `vote_average.gte`, `vote_count.gte` |
| Search | `/search/tv`, `/search/movie`, `/search/multi` | `query`, `page` |
| Details + recommendations | `/tv/{id}`, `/movie/{id}` | `append_to_response=recommendations` |
| Genre names | `/genre/tv/list`, `/genre/movie/list` | – |
| Config (optional) | `/configuration` | – returns image base URL and sizes |

Notes:

- `sort_by` values used: `popularity.desc`, `vote_average.desc`, `first_air_date.desc` (TV) /
  `primary_release_date.desc` (movies).
- `with_genres`: comma = AND, pipe `|` = OR. The app uses comma.
- Genre ids differ between movie and TV lists (for example TV *Action & Adventure* is `10759`, movie
  *Action* is `28`; *Comedy* is `35` in both). Always load them from `/genre/{kind}/list`; never hard-code.
- Rating filters on `discover` should add `vote_count.gte` (the app uses 50), otherwise titles with one 10/10 vote dominate.
- **Search cannot filter** by genre or rating, and takes only a single year. Filter search results on the client
  with `MediaFilter.matches(_:)`; use `discover` when server-side filtering is required.
- `/search/multi` returns `media_type` of `movie`, `tv` **or `person`**. Drop `person`.
- Pagination: `page` starts at 1 and is capped at 500 by TMDB. Stop when `page >= total_pages`.

## Response shapes (fields the app reads)

List response (`discover`, `search`):

```json
{
  "page": 1,
  "total_pages": 3,
  "total_results": 52,
  "results": [
    {
      "id": 1396,
      "media_type": "tv",              // only on /search/multi
      "name": "Breaking Bad",          // TV; movies use "title"
      "overview": "…",
      "first_air_date": "2008-01-20",  // TV; movies use "release_date"
      "genre_ids": [18, 80],
      "vote_average": 8.9,
      "poster_path": "/abc.jpg",       // nullable
      "backdrop_path": "/def.jpg"      // nullable
    }
  ]
}
```

Detail response adds `genres: [{id, name}]` (instead of `genre_ids`), `runtime` (movies) /
`number_of_seasons` (TV) and, with `append_to_response=recommendations`, a `recommendations` object shaped like
a list response. Most fields can be `null` or `""`; DTO properties are optional and `MediaDTO.toDomain` fills defaults.
Unknown `vote_average` arrives as `0`, which the mapper turns into `nil` ("not rated").

Error body (all non-2xx): `{"status_code": 7, "status_message": "Invalid API key: …", "success": false}`.

## Images

`https://image.tmdb.org/t/p/{size}{path}` where `path` already starts with `/`.

| Kind | Sizes |
|------|-------|
| Poster | `w92`, `w154`, `w185`, `w342`, `w500`, `w780`, `original` |
| Backdrop | `w300`, `w780`, `w1280`, `original` |

Use `w342` for grid cards and `w780` for details on a 1080p tvOS screen; avoid `original`. A `nil` path
renders a placeholder.

## Errors, rate limits and retry

| HTTP / condition | `MediaError` | Retried? |
|------------------|--------------|----------|
| 2xx, undecodable body | `decoding` | no |
| 401 | `unauthorized` | no (bad or missing token) |
| 404 | `notFound` | no |
| 429 | `rateLimited(retryAfter:)` | yes, waits `Retry-After` seconds if sent, else backoff |
| 5xx | `server(statusCode:)` | yes |
| No connectivity / transport failure | `offline` | yes |
| Task cancelled (`URLError.cancelled`) | `CancellationError` (not mapped) | no |
| anything else (3xx, other 4xx) | `server(statusCode:)` | no |

- TMDB's published limit is roughly 50 requests per second per client; verify the current figure in their
  docs. The earlier "60 requests/minute" figure was wrong. The app issues far fewer requests than that, so
  there is no client-side counter; the client reacts to `429` instead.
- Retry policy: at most 3 attempts, delay `baseDelay × 2^(attempt−1)` (500 ms, 1 s, 2 s) unless `Retry-After` is
  present. Add jitter if many clients share a network.
- Cancellation (view disappears, search text changes) must stop the request and must **not** show an error.

## Caching

- Use the `URLSession` HTTP cache: `URLCache(memoryCapacity: 20 MB, diskCapacity: 100 MB)` with
  `requestCachePolicy = .useProtocolCachePolicy`, which honours the `Cache-Control` headers TMDB returns
  (check them with `curl -I` against an authenticated request before tuning).
- No custom disk database, no Realm, no hand-rolled cache key scheme. HTTP caching keys on the full URL,
  which already includes page, filters and language.
- Offline behaviour: cached responses may be served by the system when valid; otherwise the UI shows the
  `offline` error with a retry button. Full offline mode is out of scope.

## Testing the API layer

- Unit tests inject a stub `HTTPTransport` that returns canned `(Data, HTTPURLResponse)`. Assert: auth header
  present, query items correct, status→error mapping, retry count, DTO→entity mapping.
- Fixtures: keep small JSON fixtures per endpoint under `Tests/SampleTVAPITests/Fixtures/`.
- Live tests are opt-in: they run only if the `TMDB_READ_ACCESS_TOKEN` environment variable is set and are
  never part of CI.

Useful manual check (replace `$TOKEN` with your read access token; do not paste it into shared logs):

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://api.themoviedb.org/3/discover/tv?language=en-US&page=1&sort_by=popularity.desc" | jq '.results[0]'
```

Without a token the API answers `401` with `status_code: 7`, which is a quick way to confirm connectivity.

## Terms

TMDB requires attribution (the notice and logo, see the README) and restricts the free API to
non-commercial use. Images and metadata are not for redistribution.
