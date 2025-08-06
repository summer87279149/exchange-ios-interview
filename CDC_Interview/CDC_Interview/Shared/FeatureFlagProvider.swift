
import Foundation
import RxCocoa
import RxSwift

enum FeatureFlagType {
    case supportEUR
}
protocol FeatureFlagProviderType {
    func observeFlagValue(flag: FeatureFlagType) -> Observable<Bool>
    func getValue(flag: FeatureFlagType) -> Bool
    func update(flag: FeatureFlagType, newValue: Bool)
}
class FeatureFlagProvider: FeatureFlagProviderType{
    let flagsRelay: BehaviorRelay<[FeatureFlagType: Bool]> = .init(
        value: [
            .supportEUR: false
        ]
    )
    
    func observeFlagValue(flag falg: FeatureFlagType) -> Observable<Bool> {
        flagsRelay.map {
            $0[falg] ?? false
        }
    }
    
    func getValue(flag falg: FeatureFlagType) -> Bool {
        flagsRelay.value[falg] ?? false
    }
    
    func update(flag falg: FeatureFlagType, newValue: Bool) {
        var existing = flagsRelay.value
        existing[falg] = newValue
        flagsRelay.accept(existing)
    }
}
