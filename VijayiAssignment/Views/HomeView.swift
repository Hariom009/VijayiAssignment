import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content Type Picker
                    Picker("Content Type", selection: $viewModel.selectedType) {
                        ForEach(ContentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(Color(UIColor.systemGroupedBackground))
                    
                    // Content List
                    if viewModel.isLoading && viewModel.currentTitles.isEmpty {
                        // Loading State with Shimmer
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(0..<5, id: \.self) { _ in
                                    LoadingPlaceholder()
                                }
                            }
                            .padding(.vertical)
                        }
                    } else if viewModel.currentTitles.isEmpty {
                        // Empty State
                        EmptyStateView(
                            message: "No \(viewModel.selectedType.displayName.lowercased()) found",
                            systemImage: "film"
                        )
                    } else {
                        // Content List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.currentTitles) { title in
                                    NavigationLink(destination: DetailsView(titleId: title.id)) {
                                        TitleCardView(title: title)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        .refreshable {
                            viewModel.refreshContent()
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {
                    viewModel.showError = false
                }
                Button("Retry") {
                    viewModel.refreshContent()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
