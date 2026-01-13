import Foundation
import Combine

class NetworkService {
    static let shared = NetworkService()
    private let apiKey = "JVJKr95OSEFMKjyu2zEhW7QL1HTa8Jwgq7CSjCfm"
    private let baseURL = "https://api.watchmode.com/v1"
    
    private init() {}
    
    // MARK: - Fetch Titles (Movies or TV Shows)
    func fetchTitles(type: ContentType, limit: Int = 15) -> AnyPublisher<[Title], APIError> {
        let urlString = "\(baseURL)/list-titles/?apiKey=\(apiKey)&types=\(type.rawValue)&limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        print("🌐 Fetching: \(urlString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.noData
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                // Debug: Print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📦 Raw API Response (first 500 chars): \(String(jsonString.prefix(500)))")
                }
                
                return data
            }
            .decode(type: ListTitlesResponse.self, decoder: JSONDecoder())
            .map { response in
                let titles = response.titles
                print("✅ Decoded \(titles.count) titles")
                
                // Debug: Check first title's poster URL
                if let firstTitle = titles.first {
                    print("🖼️ First title: '\(firstTitle.title)'")
                    print("🖼️ Poster URL: '\(firstTitle.posterURL ?? "NIL")'")
                }
                
                return titles
            }
            .mapError { error in
                print("❌ Error: \(error)")
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
    
    // MARK: - Fetch Both Movies and TV Shows Simultaneously using Publishers.Zip
    func fetchMoviesAndTVShows(limit: Int = 15) -> AnyPublisher<(movies: [Title], tvShows: [Title]), APIError> {
        let moviesPublisher = fetchTitles(type: .movie, limit: limit)
        let tvShowsPublisher = fetchTitles(type: .tvShow, limit: limit)
        
        return Publishers.Zip(moviesPublisher, tvShowsPublisher)
            .map { (movies: $0, tvShows: $1) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Fetch Title Details
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
