import Foundation
import RxSwift

class DetailViewModel: ObservableObject {
    @Published var showEURPrice: Bool = false
    
    private let item: CryptoPriceDataType
    private let dependencyProvider: ListViewModelDependencyProviderType
    private let disposeBag = DisposeBag()
    
    var formattedUSDPrice: String {
        return dependencyProvider.cryptoFormatter.format(value: item.usdPrice)
    }
    
    var formattedEURPrice: String {
        if let eurPrice = item.eurPrice {
            return dependencyProvider.cryptoFormatter.format(value: eurPrice)
        }
        return "--"
    }
    
    init(item: CryptoPriceDataType, dependencyProvider: ListViewModelDependencyProviderType) {
        self.item = item
        self.dependencyProvider = dependencyProvider
        setupFeatureFlags()
    }
    
    private func setupFeatureFlags() {
        showEURPrice = dependencyProvider.featureFlagProvider.getValue(flag: .supportEUR)
        dependencyProvider.featureFlagProvider.observeFlagValue(flag: .supportEUR)
            .distinctUntilChanged()
            .subscribe(with: self, onNext: { owner, newValue in
                owner.showEURPrice = newValue
            })
            .disposed(by: disposeBag)
    }
} 
