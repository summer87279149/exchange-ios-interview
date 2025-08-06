import Foundation
import RxSwift

protocol CryptoUseCaseType {
    func getCryptoPriceData(supportEUR: Bool) async throws -> [CryptoPriceDataType]
    func getCryptoPriceDataObservable(supportEUR: Bool) -> Single<[CryptoPriceDataType]>
}

final class CryptoUseCase: CryptoUseCaseType {
    private let repository: CryptoRepositoryType
    
    init(repository: CryptoRepositoryType) {
        self.repository = repository
    }
    
    func getCryptoPriceData(supportEUR: Bool) async throws -> [CryptoPriceDataType] {
        if supportEUR {
            return try await repository.fetchAllPricesAsync()
        } else {
            return try await repository.fetchUSDPricesAsync()
        }
    }
    
    func getCryptoPriceDataObservable(supportEUR: Bool) -> Single<[CryptoPriceDataType]> {
        if supportEUR {
            return repository.fetchAllPrices()
                .map { items in
                    items as [CryptoPriceDataType]
                }
        } else {
            return repository.fetchUSDPrices()
                .map { items in
                    items as [CryptoPriceDataType]
                }
        }
    }
}
