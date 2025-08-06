import Foundation
import RxSwift
protocol SettingViewModelDependencyProviderType {
    var featureFlagProvider: FeatureFlagProviderType? { get }
}
extension Dependency: SettingViewModelDependencyProviderType{}


class SettingViewModel: ObservableObject {
    @Published var supportEUR: Bool = false {
        didSet {
            featureFlagProvider?.update(flag: .supportEUR, newValue: supportEUR)
        }
    }
    
    let featureFlagProvider: FeatureFlagProviderType?
    private let dependencyProvider: ListViewModelDependencyProviderType
    
    init(dependencyProvider: ListViewModelDependencyProviderType = Dependency.shared) {
        self.dependencyProvider = dependencyProvider
        self.featureFlagProvider = dependencyProvider.featureFlagProvider
        self.supportEUR = featureFlagProvider?.getValue(flag: .supportEUR) ?? false
    }
}
