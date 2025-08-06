import Foundation
import Combine
import RxSwift
import RxRelay
import RxCocoa

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
    @Published var searchText: String = ""{
        didSet{
            searchRelay.accept(searchText)
        }
    }
    @Published var displayItems: [CryptoPriceDataType] = []
    @Published var isLoading = false
    @Published var showEURPrice: Bool = false
    
    private let useCase: CryptoUseCaseType
    private let disposeBag = DisposeBag()
    private let featureFlagProvider: FeatureFlagProviderType
    private let dependencyProvider: ListViewModelDependencyProviderType
    private var allItems = BehaviorRelay<[CryptoPriceDataType]>(value: [])
    private let searchRelay = BehaviorRelay<String>(value: "")
    
    init(dependencyProvider: ListViewModelDependencyProviderType = Dependency.shared) {
        self.dependencyProvider = dependencyProvider
        self.useCase = dependencyProvider.useCase
        self.featureFlagProvider = dependencyProvider.featureFlagProvider
        setupFeatureFlags()
        setupSearchBinding()
    }
    
    private func setupFeatureFlags() {
        featureFlagProvider.observeFlagValue(flag: .supportEUR)
            .distinctUntilChanged()
            .subscribe(with: self, onNext: { owner, newValue in
                owner.showEURPrice = newValue
            })
            .disposed(by: disposeBag)
    }
 
    private func setupSearchBinding() {
        // Remote search implementation: Triggers a new network request when search text changes
        // This implementation assumes the backend API supports search based on query parameters
        // Pros: Can search larger datasets not limited by client memory
        // Cons: Increases server load, requires network connection
        //
        // If only local filtering is needed, this part can be removed, keeping only the combineLatest part below
        searchRelay
            .skip(1)
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .withUnretained(self)
            .flatMapLatest({ owner, query in
                // flatMapLatest ensures that when a new search input occurs, previous unfinished requests are canceled
                // This avoids "race conditions" where older search results override newer ones
                owner.requstData()
            })
            .subscribe(with: self, onNext: { owner, data in
                owner.allItems.accept(data)
            })
            .disposed(by: disposeBag)
        
        // Local filtering implementation: Combines latest search text and dataset
        // Regardless of whether data comes from network requests or locally, it's filtered through this mechanism
        Observable.combineLatest(
            searchRelay.asObservable(),
            allItems.asObservable()
        )
        .observe(on: MainScheduler.instance)
        .subscribe(with: self, onNext: { owner, combined in
            let (searchQuery, items) = combined
            owner.filterItems(items: items, query: searchQuery)
        })
        .disposed(by: disposeBag)
    }
    
    // Manual refresh with loading indicator
    func refreshDataWithLoadingIndicator() async {
        isLoading = true
        defer{
            isLoading = false
        }
        let items = try? await requstData().value
        allItems.accept(items ?? [])
    }
    
    @MainActor
    private func filterItems(items: [CryptoPriceDataType], query: String) {
        if query.isEmpty {
            displayItems = items
            return
        }
        displayItems = items.filter { item in
            item.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    private func requstData() -> Single<[CryptoPriceDataType]>{
        useCase.getCryptoPriceDataObservable(supportEUR: showEURPrice)
    }
    
    func getPriceText(_ model: CryptoPriceDataType) -> String {
        var price = "Price: \(getUSDPrice(model))"
        if showEURPrice, model.eurPrice != nil{
            price = "USD: \(getUSDPrice(model)) EUR: \(getEURPrice(model))"
        }
        return price
    }
    
    func getUSDPrice(_ model: CryptoPriceDataType?) -> String{
        if let model{
            return dependencyProvider.cryptoFormatter.format(value: model.usdPrice)
        }
        return ""
    }
    
    func getEURPrice(_ model: CryptoPriceDataType? ) -> String{
        if let model,
           let eurPrice = model.eurPrice {
            return dependencyProvider.cryptoFormatter.format(value: eurPrice)
        }
        return ""
    }
}
