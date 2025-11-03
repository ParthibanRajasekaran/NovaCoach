import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published private(set) var snapshot: AnalyticsSnapshot?
    @Published var errorMessage: String?

    private let useCase: FetchAnalyticsSnapshotUseCase

    init(useCase: FetchAnalyticsSnapshotUseCase) {
        self.useCase = useCase
    }

    func load() async {
        do {
            snapshot = try await useCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
