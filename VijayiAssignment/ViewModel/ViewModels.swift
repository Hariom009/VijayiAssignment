import Foundation
import Combine

class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var movies: [Title] = []
    @Published var tvShows: [Title] = []
    @Published var selectedType: ContentType = .movie
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService.shared
    
    // MARK: - Computed Property
    var currentTitles: [Title] {
        selectedType == .movie ? movies : tvShows
    }
    
    // MARK: - Init
    init() {
        fetchContent()
    }
    
    // MARK: - Fetch Content using Publishers.Zip
    func fetchContent() {
        isLoading = true
        errorMessage = nil
        showError = false
        
        // Using limit of 15 since we fetch details for each title
        networkService.fetchMoviesAndTVShows(limit: 15)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            } receiveValue: { [weak self] result in
                guard let self = self else { return }
                self.movies = result.movies
                self.tvShows = result.tvShows
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Refresh Content
    func refreshContent() {
        fetchContent()
    }
    
    // MARK: - Toggle Content Type
    func toggleContentType() {
        selectedType = selectedType == .movie ? .tvShow : .movie
    }
}

// MARK: - Details View Model
class DetailsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var titleDetails: TitleDetails?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let networkService = NetworkService.shared
    
    // MARK: - Fetch Title Details
    func fetchDetails(for id: Int) {
        isLoading = true
        errorMessage = nil
        showError = false
        
        networkService.fetchTitleDetails(id: id)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            } receiveValue: { [weak self] details in
                guard let self = self else { return }
                self.titleDetails = details
            }
            .store(in: &cancellables)
    }
}
