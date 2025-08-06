//
//  CryptoUseCaseTests.swift
//  CDC_InterviewTests
//
//  Created by xiatian on 8/6/25.
//

import XCTest
import RxSwift
@testable import CDC_Interview

final class CryptoUseCaseTests: XCTestCase {
    
    private var mockRepository: MockCryptoRepository!
    private var useCase: CryptoUseCase!
    private var disposeBag: DisposeBag!
    
    override func setUpWithError() throws {
        mockRepository = MockCryptoRepository()
        useCase = CryptoUseCase(repository: mockRepository)
        disposeBag = DisposeBag()
    }
    
    override func tearDownWithError() throws {
        mockRepository = nil
        useCase = nil
        disposeBag = nil
    }
    
    // MARK: - Async Tests
    
    func testGetCryptoPriceData_WithoutEUR_ReturnsUSDPrices() async throws {
        // Arrange
        let expectedItems = [
            MockUSDPrice(id: 1, name: "BTC", usdPrice: 50000)
        ]
        mockRepository.stubbedUSDPrices = expectedItems
        
        // Act
        let result = try await useCase.getCryptoPriceData(supportEUR: false)
        
        // Assert
        XCTAssertEqual(result.count, expectedItems.count)
        XCTAssertEqual((result[0] as? MockUSDPrice)?.name, "BTC")
        XCTAssertEqual((result[0] as? MockUSDPrice)?.usdPrice, 50000)
        XCTAssertTrue(mockRepository.fetchUSDPricesAsyncCalled)
        XCTAssertFalse(mockRepository.fetchAllPricesAsyncCalled)
    }
    
    func testGetCryptoPriceData_WithEUR_ReturnsAllPrices() async throws {
        // Arrange
        let expectedItems = [
            MockAllPrice(id: 1, name: "BTC", usdPrice: 50000, eurPrice: 45000)
        ]
        mockRepository.stubbedAllPrices = expectedItems
        
        // Act
        let result = try await useCase.getCryptoPriceData(supportEUR: true)
        
        // Assert
        XCTAssertEqual(result.count, expectedItems.count)
        XCTAssertEqual((result[0] as? MockAllPrice)?.name, "BTC")
        XCTAssertEqual((result[0] as? MockAllPrice)?.usdPrice, 50000)
        XCTAssertEqual((result[0] as? MockAllPrice)?.eurPrice, 45000)
        XCTAssertTrue(mockRepository.fetchAllPricesAsyncCalled)
        XCTAssertFalse(mockRepository.fetchUSDPricesAsyncCalled)
    }
    
    func testGetCryptoPriceData_WithError_ThrowsError() async {
        // Arrange
        mockRepository.shouldThrowError = true
        
        // Act & Assert
        do {
            _ = try await useCase.getCryptoPriceData(supportEUR: false)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Observable Tests
    
    func testGetCryptoPriceDataObservable_WithoutEUR_ReturnsUSDPrices() {
        // Arrange
        let expectation = XCTestExpectation(description: "Fetch USD prices")
        let expectedItems = [
            MockUSDPrice(id: 1, name: "BTC", usdPrice: 50000)
        ]
        mockRepository.stubbedUSDPrices = expectedItems
        
        // Act
        useCase.getCryptoPriceDataObservable(supportEUR: false)
            .subscribe(onSuccess: { items in
                // Assert
                XCTAssertEqual(items.count, expectedItems.count)
                XCTAssertEqual((items[0] as? MockUSDPrice)?.name, "BTC")
                XCTAssertEqual((items[0] as? MockUSDPrice)?.usdPrice, 50000)
                XCTAssertTrue(self.mockRepository.fetchUSDPricesCalled)
                XCTAssertFalse(self.mockRepository.fetchAllPricesCalled)
                expectation.fulfill()
            }, onFailure: { error in
                XCTFail("Unexpected error: \(error)")
            })
            .disposed(by: disposeBag)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetCryptoPriceDataObservable_WithEUR_ReturnsAllPrices() {
        // Arrange
        let expectation = XCTestExpectation(description: "Fetch all prices")
        let expectedItems = [
            MockAllPrice(id: 1, name: "BTC", usdPrice: 50000, eurPrice: 45000)
        ]
        mockRepository.stubbedAllPrices = expectedItems
        
        // Act
        useCase.getCryptoPriceDataObservable(supportEUR: true)
            .subscribe(onSuccess: { items in
                // Assert
                XCTAssertEqual(items.count, expectedItems.count)
                XCTAssertEqual((items[0] as? MockAllPrice)?.name, "BTC")
                XCTAssertEqual((items[0] as? MockAllPrice)?.usdPrice, 50000)
                XCTAssertEqual((items[0] as? MockAllPrice)?.eurPrice, 45000)
                XCTAssertTrue(self.mockRepository.fetchAllPricesCalled)
                XCTAssertFalse(self.mockRepository.fetchUSDPricesCalled)
                expectation.fulfill()
            }, onFailure: { error in
                XCTFail("Unexpected error: \(error)")
            })
            .disposed(by: disposeBag)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetCryptoPriceDataObservable_WithError_EmitsError() {
        // Arrange
        let expectation = XCTestExpectation(description: "Emit error")
        mockRepository.shouldThrowError = true
        
        // Act
        useCase.getCryptoPriceDataObservable(supportEUR: false)
            .subscribe(onSuccess: { _ in
                XCTFail("Expected error to be emitted")
            }, onFailure: { error in
                // Assert
                XCTAssertNotNil(error)
                expectation.fulfill()
            })
            .disposed(by: disposeBag)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Classes

class MockCryptoRepository: CryptoRepositoryType {
    var stubbedUSDPrices: [CryptoPriceDataType] = []
    var stubbedAllPrices: [CryptoPriceDataType] = []
    var shouldThrowError = false
    
    var fetchUSDPricesAsyncCalled = false
    var fetchAllPricesAsyncCalled = false
    var fetchUSDPricesCalled = false
    var fetchAllPricesCalled = false
    
    func fetchUSDPricesAsync() async throws -> [CryptoPriceDataType] {
        fetchUSDPricesAsyncCalled = true
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 100, userInfo: nil)
        }
        return stubbedUSDPrices
    }
    
    func fetchAllPricesAsync() async throws -> [CryptoPriceDataType] {
        fetchAllPricesAsyncCalled = true
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 100, userInfo: nil)
        }
        return stubbedAllPrices
    }
    
    func fetchUSDPrices() -> Single<[CryptoPriceDataType]> {
        fetchUSDPricesCalled = true
        if shouldThrowError {
            return .error(NSError(domain: "TestError", code: 100, userInfo: nil))
        }
        return .just(stubbedUSDPrices)
    }
    
    func fetchAllPrices() -> Single<[CryptoPriceDataType]> {
        fetchAllPricesCalled = true
        if shouldThrowError {
            return .error(NSError(domain: "TestError", code: 100, userInfo: nil))
        }
        return .just(stubbedAllPrices)
    }
}

struct MockUSDPrice: CryptoPriceDataType {
    var id: Int
    var name: String
    var usdPrice: Decimal
    var eurPrice: Decimal? { nil }
}

struct MockAllPrice: CryptoPriceDataType {
    var id: Int
    var name: String
    var usdPrice: Decimal
    var eurPrice: Decimal?
}
