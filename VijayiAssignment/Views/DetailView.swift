import SwiftUI

struct DetailsView: View {
    let titleId: Int
    @StateObject private var viewModel = DetailsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                // Loading State
                loadingView
            } else if let details = viewModel.titleDetails {
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header with Backdrop
                        headerView(details: details)
                        
                        // Title and Basic Info
                        titleSection(details: details)
                        
                        // Stats Row
                        statsRow(details: details)
                        
                        // Overview
                        if let overview = details.plotOverview, !overview.isEmpty {
                            overviewSection(overview: overview)
                        }
                        
                        // Additional Info
                        additionalInfoSection(details: details)
                        
                        Spacer(minLength: 20)
                    }
                }
                .ignoresSafeArea(edges: .top)
            } else {
                // Empty or Error State
                EmptyStateView(
                    message: "Unable to load details",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchDetails(for: titleId)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.showError = false
            }
            Button("Retry") {
                viewModel.fetchDetails(for: titleId)
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Header View
    private func headerView(details: TitleDetails) -> some View {
        ZStack(alignment: .bottom) {
            // Backdrop Image
            if let backdropURL = details.backdrop {
                GeometryReader { geo in
                    AsyncImage(url: URL(string: backdropURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 180)
                                .shimmer()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 180)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.largeTitle)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .frame(height: 200)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 250)
            }
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [.clear, Color(UIColor.systemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            
            // Poster
            HStack {
                AsyncImage(url: URL(string: details.poster ?? "")) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 180)
                            .shimmer()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    case .failure:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 180)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .padding(.leading, 20)
                
                Spacer()
            }
            .offset(y: 60)
        }
    }
    
    // MARK: - Title Section
    private func titleSection(details: TitleDetails) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(details.title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 70)
            
            if let originalTitle = details.originalTitle, originalTitle != details.title {
                Text(originalTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Stats Row
    private func statsRow(details: TitleDetails) -> some View {
        HStack(spacing: 20) {
            // Rating
            if let rating = details.userRating {
                StatItem(
                    icon: "star.fill",
                    value: String(format: "%.1f", rating),
                    label: "Rating",
                    color: .yellow
                )
            }
            
            // Year
            if let year = details.year {
                StatItem(
                    icon: "calendar",
                    value: "\(year)",
                    label: "Year",
                    color: .blue
                )
            }
            
            // Runtime
            if details.runtime != nil {
                StatItem(
                    icon: "clock",
                    value: details.displayRuntime,
                    label: "Runtime",
                    color: .green
                )
            }
            
            // Type
            StatItem(
                icon: details.type == "movie" ? "film" : "tv",
                value: details.type.capitalized,
                label: "Type",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Overview Section
    private func overviewSection(overview: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(overview)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Additional Info Section
    private func additionalInfoSection(details: TitleDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Information")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if let genres = details.genreNames, !genres.isEmpty {
                    InfoRow(label: "Genres", value: details.genresString)
                }
                
                if let releaseDate = details.releaseDate {
                    InfoRow(label: "Release Date", value: releaseDate)
                }
                
                if let imdbID = details.imdbID {
                    InfoRow(label: "IMDb ID", value: imdbID)
                }
                
                if let criticScore = details.criticScore {
                    InfoRow(label: "Critic Score", value: "\(criticScore)%")
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Stat Item Component
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DetailsView(titleId: 1)
        }
    }
}
