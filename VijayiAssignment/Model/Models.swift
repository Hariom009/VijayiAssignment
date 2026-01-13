import Foundation

// MARK: - Content Type Enum
enum ContentType: String, CaseIterable {
    case movie = "movie"
    case tvShow = "tv_series"
    
    var displayName: String {
        switch self {
        case .movie:
            return "Movies"
        case .tvShow:
            return "TV Shows"
        }
    }
}

// MARK: - List Titles Response
struct ListTitlesResponse: Codable {
    let titles: [Title]
}

// MARK: - Title Model
struct Title: Codable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String?
    let type: String
    let imdbID: String?
    let tmdbID: Int?
    let tmdbType: String?
    let year: Int?
    let releaseDate: String?
    let posterURL: String?
    let userRating: Double?
    let criticScore: Int?
    let relevancePercentile: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case originalTitle = "original_title"
        case type
        case imdbID = "imdb_id"
        case tmdbID = "tmdb_id"
        case tmdbType = "tmdb_type"
        case year
        case releaseDate = "release_date"
        case posterURL = "poster"
        case userRating = "user_rating"
        case criticScore = "critic_score"
        case relevancePercentile = "relevance_percentile"
    }
    
    // Computed property for display rating
    var displayRating: String {
        if let rating = userRating {
            return String(format: "%.1f", rating)
        }
        return "N/A"
    }
}

// MARK: - Title Details Response
struct TitleDetails: Codable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String?
    let plotOverview: String?
    let type: String
    let runtime: Int?
    let year: Int?
    let releaseDate: String?
    let poster: String?
    let backdrop: String?
    let genres: [Int]?
    let genreNames: [String]?
    let userRating: Double?
    let criticScore: Int?
    let imdbID: String?
    let tmdbID: Int?
    let tmdbType: String?
    let trailer: String?
    let trailerThumbnail: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case originalTitle = "original_title"
        case plotOverview = "plot_overview"
        case type
        case runtime = "runtime_minutes"
        case year
        case releaseDate = "release_date"
        case poster
        case backdrop
        case genres
        case genreNames = "genre_names"
        case userRating = "user_rating"
        case criticScore = "critic_score"
        case imdbID = "imdb_id"
        case tmdbID = "tmdb_id"
        case tmdbType = "tmdb_type"
        case trailer
        case trailerThumbnail = "trailer_thumbnail"
    }
    
    var displayRating: String {
        if let rating = userRating {
            return String(format: "%.1f", rating)
        }
        return "N/A"
    }
    
    var displayRuntime: String {
        guard let runtime = runtime else { return "N/A" }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    var genresString: String {
        genreNames?.joined(separator: ", ") ?? "N/A"
    }
}

// MARK: - API Error
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with code: \(code)"
        }
    }
}
