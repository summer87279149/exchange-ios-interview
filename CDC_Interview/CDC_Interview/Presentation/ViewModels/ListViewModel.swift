import Foundation
import RxSwift
protocol ListViewModelDependencyProviderType {
    var useCase: CryptoUseCaseType { get }
    var featureFlagProvider: FeatureFlagProviderType { get }
    var cryptoFormatter: CryptoFormatter { get }
}

extension Dependency: ListViewModelDependencyProviderType{
    var useCase: any CryptoUseCaseType {
        resolve(CryptoUseCaseType.self)!
    }
    
    var featureFlagProvider: any FeatureFlagProviderType {
        resolve(FeatureFlagProviderType.self)!
    }
    
    var cryptoFormatter: CryptoFormatter {
        resolve(CryptoFormatter.self)!
    }
}

@MainActor
class ListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var displayItems: [any PriceViewModelType] = []
    @Published var isLoading = false
    @Published var showEURPrice: Bool = false
    
    private let useCase: CryptoUseCaseType
    private let disposeBag = DisposeBag()
    private let featureFlagProvider: FeatureFlagProviderType
    private let dependencyProvider: ListViewModelDependencyProviderType
    init(dependencyProvider: ListViewModelDependencyProviderType = Dependency.shared) {
        self.dependencyProvider = dependencyProvider
        self.useCase = dependencyProvider.useCase
        self.featureFlagProvider = dependencyProvider.featureFlagProvider
        setupFeatureFlags()
    }
    
    private func setupFeatureFlags() {
        featureFlagProvider.observeFlagValue(flag: .supportEUR)
            .distinctUntilChanged()
            .subscribe(with: self, onNext: { owner, newValue in
                owner.showEURPrice = newValue
            })
            .disposed(by: disposeBag)
    }
    
    func fetchItems(showLoading:Bool = false) async {
        if showLoading{
            isLoading = true
        }
        defer{
            isLoading = false
        }
        let items = try? await useCase.getCryptoPriceData(supportEUR: showEURPrice)
        displayItems = items ?? []
        
    }
    
    func getPriceText(_ model: any PriceViewModelType) -> String {
        var price = "Price: \(getUSDPrice(model))"
        if showEURPrice, model.eurPrice != nil{
            price = "USD: \(getUSDPrice(model)) EUR: \(getEURPrice(model))"
        }
        return price
    }
    
    func getUSDPrice(_ model: (any PriceViewModelType)?) -> String{
        if let model{
            return dependencyProvider.cryptoFormatter.format(value: model.usdPrice)
        }
        return ""
    }
    
    func getEURPrice(_ model: (any PriceViewModelType)? ) -> String{
        if let model,
           let eurPrice = model.eurPrice {
            return dependencyProvider.cryptoFormatter.format(value: eurPrice)
        }
        return ""
    }
}
