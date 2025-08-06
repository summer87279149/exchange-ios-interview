import Foundation
import RxSwift

class DetailViewModel: ObservableObject {
    @Published var showEURPrice: Bool = false
    
    private let item: CryptoPriceDataType
    private let dependencyProvider: ListViewModelDependencyProviderType
    private let disposeBag = DisposeBag()
    
    var formattedUSDPrice: String {
        if let cryptoFormatter = dependencyProvider.cryptoFormatter {
            return cryptoFormatter.format(value: item.usdPrice)
        }
        return ""
    }
    
    var formattedEURPrice: String {
        if let eurPrice = item.eurPrice, let cryptoFormatter = dependencyProvider.cryptoFormatter {
            return cryptoFormatter.format(value: eurPrice)
        }
        return "--"
    }
    
    init(item: CryptoPriceDataType, dependencyProvider: ListViewModelDependencyProviderType) {
        self.item = item
        self.dependencyProvider = dependencyProvider
        setupFeatureFlags()
    }
    
    private func setupFeatureFlags() {
        showEURPrice = dependencyProvider.featureFlagProvider?.getValue(flag: .supportEUR) ?? false
        dependencyProvider.featureFlagProvider?.observeFlagValue(flag: .supportEUR)
            .distinctUntilChanged()
            .subscribe(with: self, onNext: { owner, newValue in
                owner.showEURPrice = newValue
            })
            .disposed(by: disposeBag)
    }
} 
