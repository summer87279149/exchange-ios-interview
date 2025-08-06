import Foundation
import RxSwift
protocol CryptoRepositoryType {
    func fetchUSDPricesAsync() async throws -> [USDPrice.Price]
    func fetchAllPricesAsync() async throws -> [AllPrice.Price]
    func fetchUSDPrices() -> Single<[USDPrice.Price]>
    func fetchAllPrices() -> Single<[AllPrice.Price]>
}

class CryptoRepository: CryptoRepositoryType {
    private let networkService: NetworkServiceType
    
    init(networkService: NetworkServiceType = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchUSDPrices() -> Single<[USDPrice.Price]> {
         networkService
            .loadLocalJSONObservable(filename: "usdPrices")
            .map { (usdPrice: USDPrice) in usdPrice.data }
    }
    
    func fetchUSDPricesAsync() async throws -> [USDPrice.Price] {
         try await networkService
            .loadLocalJSONObservable(filename: "usdPrices")
            .map { (usdPrice: USDPrice) in usdPrice.data }
            .value
    }

    func fetchAllPrices() -> Single<[AllPrice.Price]> {
         networkService
            .loadLocalJSONObservable(filename: "allPrices")
            .map { (allPrice: AllPrice) in allPrice.data }
    }

    func fetchAllPricesAsync() async throws -> [AllPrice.Price] {
         try await networkService
            .loadLocalJSONObservable(filename: "allPrices")
            .map { (allPrice: AllPrice) in allPrice.data }
            .value
    }
}
