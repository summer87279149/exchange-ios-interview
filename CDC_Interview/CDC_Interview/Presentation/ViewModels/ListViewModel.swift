import Foundation
import RxSwift

@MainActor
class ListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var displayItems: [any PriceViewModelType] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showEURPrice: Bool = false
    
    private let useCase: CryptoUseCaseType
    private let featureFlagProvider: FeatureFlagProviderType
    private let disposeBag = DisposeBag()
    
    init(useCase: CryptoUseCaseType ,featureFlagProvider: FeatureFlagProviderType) {
        self.useCase = useCase
        self.featureFlagProvider = featureFlagProvider
        
        setupFeatureFlags()
    }
    
    private func setupFeatureFlags() {
        featureFlagProvider.observeFlagValue(flag: .supportEUR)
            .distinctUntilChanged()
            .subscribe(with: self, onNext: { owner, newValue in
                owner.showEURPrice = newValue
                Task {
                    await owner.fetchItems(showLoading: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func fetchItems(showLoading: Bool = false) async {
        if showLoading {
            isLoading = true
        }
        
        do {
            displayItems = try await useCase.getCryptoPriceData(supportEUR: showEURPrice) ?? []
            error = nil
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}
