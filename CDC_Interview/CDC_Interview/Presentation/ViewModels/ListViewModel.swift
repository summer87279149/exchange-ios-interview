import Foundation
import Combine
import RxSwift
import RxRelay
import RxCocoa

protocol ListViewModelDependencyProviderType {
    var useCase: CryptoUseCaseType? { get }
    var featureFlagProvider: FeatureFlagProviderType? { get }
    var cryptoFormatter: CryptoFormatter? { get }
}

extension Dependency: ListViewModelDependencyProviderType{
    var useCase: (any CryptoUseCaseType)? {
        resolve(CryptoUseCaseType.self)
    }
    
    var featureFlagProvider: (any FeatureFlagProviderType)? {
        resolve(FeatureFlagProviderType.self)
    }
    
    var cryptoFormatter: CryptoFormatter? {
        resolve(CryptoFormatter.self)
    }
}

@MainActor
final class ListViewModel: ObservableObject {
    @Published var searchText: String = ""{
        didSet{
            searchRelay.accept(searchText)
        }
    }
    @Published var displayItems: [CryptoPriceDataType] = []
    
    @Published var showEURPrice: Bool = false
    
    private let useCase: CryptoUseCaseType?
    private let disposeBag = DisposeBag()
    private let featureFlagProvider: FeatureFlagProviderType?
    private let dependencyProvider: ListViewModelDependencyProviderType
    private var allItems = BehaviorRelay<[CryptoPriceDataType]>(value: [])
    private let searchRelay = BehaviorRelay<String>(value: "")
    private let refreshRelay = PublishRelay<Void>()
    
    init(dependencyProvider: ListViewModelDependencyProviderType = Dependency.shared) {
        self.dependencyProvider = dependencyProvider
        self.useCase = dependencyProvider.useCase
        self.featureFlagProvider = dependencyProvider.featureFlagProvider
        setupBindings()
    }
    
    
    private func setupBindings() {
        guard let featureFlagProvider else { return }
        
        // Why combine these three streams:
        // 1. searchRelay: User search input, assuming we need to refresh data to ensure current data is up-to-date
        // 2. featureFlagProvider: EUR support status changes require data refresh
        // 3. refreshRelay: Refresh trigger, refreshes data when entering CryptoListView
        //
        // Benefits of combining these streams:
        // 1. Unified data fetching logic: Whether it's search changes, setting changes, or manual refresh, all handled through the same data stream
        // 2. Avoid duplicate code: No need to write separate data fetching logic for each case
        Observable.combineLatest(
            searchRelay.debounce(.milliseconds(200), scheduler: MainScheduler.instance).distinctUntilChanged(),
            featureFlagProvider.observeFlagValue(flag: .supportEUR).distinctUntilChanged().catchAndReturn(false),
            refreshRelay.startWith(())
        )
        .withUnretained(self)
        .flatMapLatest({ owner, combined in
            // flatMapLatest ensures that when a new search input occurs, previous unfinished requests are canceled
            // This avoids "race conditions" where older search results override newer ones
            let (_, showEUR, _) = combined
            return owner.requstData(supportEUR: showEUR).catchAndReturn([])
        })
        .observe(on: MainScheduler.instance)
        .subscribe(with: self, onNext: { owner, data in
            owner.allItems.accept(data)
            owner.showEURPrice = featureFlagProvider.getValue(flag: .supportEUR)
        }, onError: { owner, _ in
            owner.allItems.accept([])
            owner.showEURPrice = featureFlagProvider.getValue(flag: .supportEUR)
        })
        .disposed(by: disposeBag)
        
        // Filter data when search text changes or current allItems data changes
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
    
    // Refresh data when entering CryptoListView
    func refreshData() async {
        refreshRelay.accept(())
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
    
    private func requstData(supportEUR: Bool) -> Single<[CryptoPriceDataType]>{
        if let useCase {
            return useCase.getCryptoPriceDataObservable(supportEUR: supportEUR)
        }
        return .just([])
    }
    
    func getPriceText(_ model: CryptoPriceDataType) -> String {
        var price = "Price: \(getUSDPrice(model))"
        if showEURPrice, model.eurPrice != nil{
            price = "USD: \(getUSDPrice(model)) EUR: \(getEURPrice(model))"
        }
        return price
    }
    
    func getUSDPrice(_ model: CryptoPriceDataType) -> String{
        dependencyProvider.cryptoFormatter?.format(value: model.usdPrice) ?? ""
    }
    
    func getEURPrice(_ model: CryptoPriceDataType) -> String{
        if let eurPrice = model.eurPrice, let cryptoFormatter = dependencyProvider.cryptoFormatter {
            return cryptoFormatter.format(value: eurPrice)
        }
        return ""
    }
}
