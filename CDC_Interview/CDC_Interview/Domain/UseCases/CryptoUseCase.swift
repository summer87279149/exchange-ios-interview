import Foundation

protocol CryptoUseCaseType {
    func getCryptoPriceData(supportEUR: Bool) async throws -> [CryptoPriceDataType]
}


class CryptoUseCase: CryptoUseCaseType {
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
}
