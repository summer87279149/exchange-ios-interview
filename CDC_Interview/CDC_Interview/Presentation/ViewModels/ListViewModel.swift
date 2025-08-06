import Foundation
import RxSwift
@MainActor
class ListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var displayItems: [USDPrice.Price] = []

    private let dependency: Dependency = .shared
//    private let useCase: USDPriceUseCase = .shared
    private let featureFlagProvider: FeatureFlagProvider

    init() {
        self.featureFlagProvider = dependency.resolve(FeatureFlagProvider.self)!
    }

    func fetchItems() async {
//        let items = try? await useCase.fetchItemsAsync()
//        displayItems = items ?? []
    }
}
