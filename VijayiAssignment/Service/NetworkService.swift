import Foundation
import Combine

class NetworkService {
    static let shared = NetworkService()
    private let apiKey = "JVJKr95OSEFMKjyu2zEhW7QL1HTa8Jwgq7CSjCfm"
    private let baseURL = "https://api.watchmode.com/v1"
    
    private init() {}
    
    // MARK: - Fetch Titles with Images (using title details endpoint)
    func fetchTitles(type: ContentType, limit: Int = 15) -> AnyPublisher<[Title], APIError> {
        // First, get list of title IDs
        let urlString = "\(baseURL)/list-titles/?apiKey=\(apiKey)&types=\(type.rawValue)&limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        print("🌐 Step 1: Fetching title IDs for \(type.displayName)...")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.serverError(0)
                }
                return data
            }
            .decode(type: ListTitlesResponse.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return APIError.decodingError
                } else if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.networkError(error)
                }
            }
            .flatMap { response -> AnyPublisher<[Title], APIError> in
                let titleIDs = Array(response.titles.prefix(limit))
                print("✅ Got \(titleIDs.count) title IDs")
                print("🌐 Step 2: Fetching details (with posters) for each title...")

                let publishers = titleIDs.map { basicTitle -> AnyPublisher<Title, APIError> in
                    self.fetchTitleWithDetails(id: basicTitle.id)
                }

                return Publishers.MergeMany(publishers)
                    .collect()
                    .map { titles in
                        print("✅ Successfully loaded \(titles.count) titles with images")
                        if let first = titles.first {
                            print("🖼️ Sample title: '\(first.title)'")
                            print("🖼️ Sample poster: '\(first.posterURL ?? "NIL")'")
                        }
                        return titles
                    }
                    .eraseToAnyPublisher()
            }
            .catch { error -> AnyPublisher<[Title], APIError> in
                print("❌ Error: \(error)")
                if let apiError = error as? APIError {
                    return Fail(error: apiError).eraseToAnyPublisher()
                } else {
                    return Fail(error: APIError.networkError(error)).eraseToAnyPublisher()
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Fetch Title with Details (private helper)
    private func fetchTitleWithDetails(id: Int) -> AnyPublisher<Title, APIError> {
        let urlString = "\(baseURL)/title/\(id)/details/?apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.serverError(0)
                }
                return data
            }
            .decode(type: TitleDetails.self, decoder: JSONDecoder())
            .map { details in
                // Convert TitleDetails to Title
                Title(
                    id: details.id,
                    title: details.title,
                    originalTitle: details.originalTitle,
                    type: details.type,
                    imdbID: details.imdbID,
                    tmdbID: details.tmdbID,
                    tmdbType: details.tmdbType,
                    year: details.year,
                    releaseDate: details.releaseDate,
                    posterURL: details.poster,  // This has the actual poster URL!
                    userRating: details.userRating,
                    criticScore: details.criticScore,
                    relevancePercentile: nil
                )
            }
            .catch { error -> AnyPublisher<Title, APIError> in
                // If a single title fails, don't fail the whole batch
                // Return empty publisher to skip this title
                return Empty<Title, APIError>().eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Fetch Both Movies and TV Shows Simultaneously using Publishers.Zip
    func fetchMoviesAndTVShows(limit: Int = 15) -> AnyPublisher<(movies: [Title], tvShows: [Title]), APIError> {
        let moviesPublisher = fetchTitles(type: .movie, limit: limit)
        let tvShowsPublisher = fetchTitles(type: .tvShow, limit: limit)
        
        print("🚀 Starting parallel fetch for Movies and TV Shows...")
        
        return Publishers.Zip(moviesPublisher, tvShowsPublisher)
            .map { movies, tvShows in
                print("🎉 Parallel fetch complete!")
                print("   Movies: \(movies.count)")
                print("   TV Shows: \(tvShows.count)")
                return (movies: movies, tvShows: tvShows)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Fetch Title Details (for details screen)
    func fetchTitleDetails(id: Int) -> AnyPublisher<TitleDetails, APIError> {
        let urlString = "\(baseURL)/title/\(id)/details/?apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.noData
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: TitleDetails.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return APIError.decodingError
                } else if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.networkError(error)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
