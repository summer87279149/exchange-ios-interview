import Foundation
import RxSwift
protocol CryptoRepositoryType {
    func fetchUSDPricesAsync() async throws -> [USDPrice.Price]
    func fetchAllPricesAsync() async throws -> [AllPrice.Price]
    func fetchUSDPrices() -> Observable<[USDPrice.Price]>
    func fetchAllPrices() -> Observable<[AllPrice.Price]>
}

class CryptoRepository: CryptoRepositoryType {
    private let networkService: NetworkServiceType
    
    init(networkService: NetworkServiceType = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchUSDPrices() -> Observable<[USDPrice.Price]> {
        return networkService
            .loadLocalJSONObservable(filename: "usdPrices")
            .map { (usdPrice: USDPrice) in usdPrice.data }
            .delay(.seconds(2), scheduler: ConcurrentDispatchQueueScheduler(qos: .background)) // Simulate network delay
            .observe(on: MainScheduler.instance) // Switch to main thread for UI updates
    }
    
    func fetchUSDPricesAsync() async throws -> [USDPrice.Price] {
        // Add 2-second delay to simulate network latency
        try await Task.sleep(nanoseconds: 2_000_000_000)        
        let usdPrice: USDPrice = try await networkService.loadLocalJSON(filename: "usdPrices")
        return usdPrice.data
    }

    func fetchAllPrices() -> Observable<[AllPrice.Price]> {
        return networkService
            .loadLocalJSONObservable(filename: "allPrices")
            .map { (allPrice: AllPrice) in allPrice.data }
            .delay(.seconds(2), scheduler: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
    }

    func fetchAllPricesAsync() async throws -> [AllPrice.Price] {
        // Add 2-second delay to simulate network latency
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        let allPrice: AllPrice = try await networkService.loadLocalJSON(filename: "allPrices")
        return allPrice.data
    }
}
