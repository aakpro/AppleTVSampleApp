# API_SPECS.md - TMDB Integration Specifications

> 🌐 This document details the TMDB API integration layer architecture, endpoint specifications, request handling, and caching strategy for SampleTV's data layer.

---

## 🔑 TMDB API Configuration

### Base URL & Credentials:
```bash
# .env file (gitIgnores this!)
TMDB_API_KEY=your_tmdb_api_key_here  
API_ENDPOINT_BASE=https://api.themoviedb.org/3
API_VERSION=v3
REQ_TIMEOUT_MS=30000 // 30 second timeout for API call
MAX_RETRY_COUNT=3 // exponential backoff retries
RATE_LIMIT_WAIT_SECS=15 // wait between requests if rate limited
```

---

## 📡 Key Endpoints & Integration Patterns

### **Endpoint 1: Discover TV Shows**  
**Purpose**: Get a paginated list of shows based on filters  

```bash
POST /discover/tv
Authorization-Bearer: ${TMDB_API_KEY}

Query Parameters:
- page=1 (page number, default 1)
- api_key=${TMDB_API_KEY}
- with_genres=9485 // Comedy
- network_title_filter="HBO Show"
- sort_by=relevance (popular, rating_desc, popularity, year)

Expected Response:
{
    "page": 1,
    "results": [
        {
            "id": 12345,
            "name": show_name,
            "overview": description,
            "first_air_date": "2020-12-31",
            "vote_average": 8.5,
            "popularity": 99.8,
            "genres": [76, 10759],
            "network_id": 4,
            "poster_path": "/path.jpg"
        }
    ],
    "total_pages": 15,
    "api_version": "v3"
}  
```

#### Implementation (`sampletv-api-swift-package`):

```swift
// Protocol API
protocol TVContentRepository: TVContentProtocol {
    func fetchTVList(page: Int) async throws -> [TVContentPageResult]
}

// Implementation
class TMDBTVClientImpl: TVContentRepository {
    private let apiEndpoint = "\(API_ENDPOINT_BASE)/discover/tv"
    private let key = ProcessInfo().environment["TMDB_API_KEY"] ?? ""
    
    func fetchTVList(page: Int = 1) async throws -> [TVContentPageResult] {
        // Use URLSession with timeout + rate limiting
        do {
            let request = URLRequest(
                url: URL(string: "\(apiEndpoint)?page=\(page)&with_genres=9485")!
            )
            
            var task = URLSession(dataTaskWith: request) as URLSessionDataTask
            return try await withCheckContinuation(task, { (result) -> Data in
                
                guard let data = result.data else { throw NetworkError.failed }
                do {
                    // Decode response using TMDBTVPageResult struct
                    if let page = try JSONDecoder().decode(TMDBTVPageResult.self, 
                                                           from: data) {
                        return page.results.map { movie in Movie(id: $.id, ...) }
                    } else { throw APIError.invalidResponse }
                } catch { throw APIError.decodingFailed }
            })
        } catch { 
            // Handle network failure
            throw NetworkError.failed(error: error)
        }
    }
}
```

---

### **Endpoint 2: Get TV Details**  
**Purpose**: Retrieve detailed information for a single show  

```bash
GET /tv/{id}
Authorization-Bearer: ${TMDB_API_KEY}

Example:
GET https://api.themoviedb.org/3/tv/12345?api_key=${TMDB_API_KEY}

Response:
{
    "id": 12345,
    "name": "Show Title",
    "overview": "Long form description...",
    "original_language": "en",
    "number_of_seasons": 5,
    "first_air_date": "2020-01-01",
    "last_air_date": "2024-12-31T00:00:00Z",
    "status": "Ended", // Or "Ongoing"  
    "seasons": [/* array */],
    "episodes_averages": [/* array */],
    "credits": {
        "cast": [/* cast data */],
        "crew": [/* crew data */]
    }
}
```

---

### **Endpoint 3: Search Content**  
**Purpose**: Full-text search across movies and shows  

```bash
POST /search
Authorization-Bearer: ${TMDB_API_KEY}

Query Parameters:
- page=1
- with_media_type=movies (or tv = TV only)
- api_key=${TMDB_API_KEY}
- query="The Queen's Gambit"

Response:
{
    "page": 1,
    "results": [ /* Search Result Array */],
    "total_pages": 5,
    "api_version": "v3"
}
```

---

### **Endpoint 4: Personalized Recommendations**  
**Purpose**: Get shows similar to user's viewed content  

```bash
POST /recommendation
Authorization-Bearer: ${TMDB_API_KEY}

Query Parameters:
- id=12345 // target show ID
- with_genres=76 // limit to specific genres  
- api_key=${TMDB_API_KEY}

Response:
{
    "page": 1, 
    "results": [/* recommended show data */],
    "total_pages": 3,
    "api_version": "v3"
}  
```

---

## ⚙️ Request Handling Specifications

### Rate Limiting Implementation

TMDB API uses a simple rate-limit counter (60 requests/min default):  

```swift
class TMDBRateLimiter {
    private var requestCount: Int = 0
    
    func isAllowed() throws -> (delayInSeconds: TimeInterval, canRetry: Bool) {
        guard TMDBAPI_MAX_RATE > 0 else { throw RateLimitTooHigh }
        
        requestCount += 1
        
        if requestCount > TMDBAPI_MAX_RATE {
            let delay = RequestDelayStrategy.backoff(at: 2, multiplier: 1.5)
            return (delay, true) // wait and retry later
        }
        
        return (0, false) 
    }
    
    static func resetAfterRequest(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncafter(deadline: .now() + RequestDelayStrategy.delay(at: 2)) {
            completion()
        }
    }
}
```

### Timeout & Error Handling

All network calls use URLSession with configured timeout:  

```swift
extension URLSession {
    static var sampleTVClient: URLSessionProtocol {
        return Self(
            configuration: .default,
            maxConcurrencyLimit: 10,
            timeoutInterval: TimeInterval(REQ_TIMEOUT_MS)
        )
    }
}
```

### Caching Strategy (`sampletv-api-swift-package`):

#### Hybrid Cache Implementation:
```swift
// Memory Layer (in-process dict) + Disk Layer (async-write Realm/JSON file)  
protocol CacheManager {
    func getTVListForID(id: Int, page: Int) throws -> TVContentPageResult?
    func storeMovie(tvMovie: Movie, metadata: MetadataData) throws 
}

// Memory layer - fast access but evicts on crash/cleanup
// Disk layer - persists even for app restart  
```

#### Cache Key Strategy:
```swift
// Use a composite key: showID + requestPage + (timestamp if stale check needed)
class HybridCacheManager {
    struct CacheKey {
        let tvId: Int
        let page: Int
        
        var string: String { 
            "\(tvId)/\(page)" 
        }
    }
    
    func cache(for key: CacheKey, value: TVContentPageResult) throws -> Void {
        // Store in memory first (fast access)
        storeInMemory(key: key.string, value: value)
        
        // Persist to disk with async write
        try await storeToDisk(key: key.string, data: Data(value))
    }
    
    func retrieve<T>(cacheKey: CacheKey) throws -> T {
        // Try memory cache first
        guard let result = getFromMemory(forKey: cacheKey.string) else {
            // Fall back to disk cache (async with timeout, max 1 sec) 
        }
    }
}
```

---

## 🎯 Use Case Interface Specifications

### Pure Domain Use Cases (No Dependencies):

```swift
// sampletv-domain-swift-package/Sources/UseCases/GetMovies.swift
    
protocol GetTVShowUseCaseProtocol {
    func execute(tvId: Int, filterGenres: [Int]?) throws -> TVShowResult
}

// Implementation - pure Swift, no external imports allowed  
struct GetTVImplementation: GetTVShowUseCaseProtocol {
    func execute(tvId: Int, filterGenres: [Int]?) throws -> TVShowResult {
        return try await cleanExecution(
            tvId: tvId,
            genresFilter: filterGenres ?? []
        )
    }
    
    private func cleanExecution(tvId: Int, genresFilter: [Int]) throws -> TVShow {
        // Business logic only - no network/API calls
        let result = try await UseCaseAPI.execute(
            apiEndpoint: "/tv/\(tvId)/",
            id: tvId,
            with_genres: genresFilter.joined(separator: ",")
        )
        
        return MapDomainResult(result, tvId) { data in
            // Domain-specific transformation only
        }
    }
}  
```

---

## 🧪 Integration Test Specifications

### Expected API Responses (Test Cases):

#### Test Case 1: Valid Fetch Request (Single Show)
```
Input: GET /tv/47085?api_key={API_KEY}
Status: 200 OK
Expected Output:
{
    "id": 47085,
    "name": "Breaking Bad", 
    "overview": "Describing the show...",
    "status": "Ended", 
    "number_of_seasons": 5
}
```

#### Test Case 2: Invalid Show ID Request
```
Input: GET /tv/999999?api_key={API_KEY}  
Status: 404 Not Found
Expected Output: APIError.invalidResponse
```

#### Test Case 3: Rate Limit Exceeded (Repeated Calls)
```
Input: Rapid-fire requests over 60 req/min threshold
Status: Rate limiting active
Expected Output: NetworkError.throws, wait before retry
```

---

## 🛡️ Error Contract

### TMDB API Errors Mapped to Swift Enum:

```swift
// sampletv-api-swift-package/Sources/Networking/APIProtocols.swift

enum APIError: Equatable, CustomStringConvertible {
    case networkFailure(Error)
    case decodingFailed(Error)
    case invalidId(Int)
    case rateLimitExceeded(Error?)
    case notFound(Int)
    
    var description: String { 
        switch self {
        case .networkFailure(let error):
            return "Network error. Check your API key."
        case .decodingFailed(let error):
            return "JSON parsing failed."
        case .invalidId(let id):
            return "Invalid TV show ID: \(id)"  
        case .rateLimitExceeded(let error): 
            return "API rate limit exceeded. Wait before retrying."
        case .notFound(let id):
            return "TV Show not found with ID: \(id)"
        }
    }
    
    // Add localized translations for end-user messages
}

enum NetworkError: Error, CustomStringConvertible { 
    case requestTimeout  
    case connectionFailed(Error)
    
    var description: String {
        switch self {
        case .requestTimeout: return "Request timed out."
        case .connectionFailed(let error): return "Network unavailable."
        }
    }
}  
```

---

## 🔒 Security & Privacy Considerations (N/A for Open API)

- ✅ No PII transmitted via API requests
- ✅ API key stored only in `.env` file (never hard-coded)
- ✅ No external server-side code - all processing is client-side

---

*This document serves as the authoritative specification for all network-related implementations across SampleTV's API layer.*
