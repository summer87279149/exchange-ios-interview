import Foundation
import RxSwift
protocol CryptoRepositoryType {
    func fetchUSDPricesAsync() async throws -> [CryptoPriceDataType]
    func fetchAllPricesAsync() async throws -> [CryptoPriceDataType]
    func fetchUSDPrices() -> Single<[CryptoPriceDataType]>
    func fetchAllPrices() -> Single<[CryptoPriceDataType]>
}

final class CryptoRepository: CryptoRepositoryType {
    private let networkService: NetworkServiceType
    
    init(networkService: NetworkServiceType = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchUSDPrices() -> Single<[CryptoPriceDataType]> {
         networkService
            .loadLocalJSONObservable(filename: "usdPrices")
            .map { (usdPrice: USDPrice) in usdPrice.data }
    }
    
    func fetchUSDPricesAsync() async throws -> [CryptoPriceDataType] {
         try await networkService
            .loadLocalJSONObservable(filename: "usdPrices")
            .map { (usdPrice: USDPrice) in usdPrice.data }
            .value
    }

    func fetchAllPrices() -> Single<[CryptoPriceDataType]> {
         networkService
            .loadLocalJSONObservable(filename: "allPrices")
            .map { (allPrice: AllPrice) in allPrice.data }
    }

    func fetchAllPricesAsync() async throws -> [CryptoPriceDataType] {
         try await networkService
            .loadLocalJSONObservable(filename: "allPrices")
            .map { (allPrice: AllPrice) in allPrice.data }
            .value
    }
}
