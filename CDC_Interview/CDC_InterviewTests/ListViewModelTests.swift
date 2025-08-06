import XCTest
import RxTest
import RxSwift
import RxCocoa
@testable import CDC_Interview
@MainActor
final class ListViewModelTests: XCTestCase {
    
    private var mockUseCase: MockCryptoUseCase!
    private var mockFeatureFlagProvider: FeatureFlagProvider!
    private var mockFormatter: MockFormatter!
    private var mockDependencyProvider: MockDependencyProvider!
    private var disposeBag: DisposeBag!
    
    override func setUpWithError() throws {
        mockUseCase = MockCryptoUseCase()
        mockFeatureFlagProvider = FeatureFlagProvider()
        mockFormatter = MockFormatter()
        mockDependencyProvider = MockDependencyProvider(
            useCase: mockUseCase,
            featureFlagProvider: mockFeatureFlagProvider,
            cryptoFormatter: mockFormatter
        )
        disposeBag = DisposeBag()
    }
    
    override func tearDownWithError() throws {
        mockUseCase = nil
        mockFeatureFlagProvider = nil
        mockFormatter = nil
        mockDependencyProvider = nil
        disposeBag = nil
    }
    
    
    func testGetUSDPrice() {
        // Arrange
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        let priceItem = MockPriceItem(id: 1, name: "BTC", usdPrice: 123.45, eurPrice: nil)
        
        // Act
        let result = viewModel.getUSDPrice(priceItem)
        
        // Assert
        XCTAssertEqual(result, "formatted_123.45")
    }
    
    
    func testGetEURPrice() {
        // Arrange
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        let priceItem = MockPriceItem(id: 1, name: "BTC", usdPrice: 123.45, eurPrice: 234.56)
        
        // Act
        let result = viewModel.getEURPrice(priceItem)
        
        // Assert
        XCTAssertEqual(result, "formatted_234.56")
    }
    
    func testGetEURPrice_NilEURPrice() {
        // Arrange
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        let priceItem = MockPriceItem(id: 1, name: "BTC", usdPrice: 123.45, eurPrice: nil)
        
        // Act
        let result = viewModel.getEURPrice(priceItem)
        
        // Assert
        XCTAssertEqual(result, "")
    }
    
    
    func testGetPriceText_OnlyUSD() {
        // Arrange
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        viewModel.showEURPrice = false
        let priceItem = MockPriceItem(id: 1, name: "BTC", usdPrice: 123.45, eurPrice: 234.56)
        
        // Act
        let result = viewModel.getPriceText(priceItem)
        
        // Assert
        XCTAssertEqual(result, "Price: formatted_123.45")
    }
    
    func testGetPriceText_USDAndEUR() {
        // Arrange
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        viewModel.showEURPrice = true
        let priceItem = MockPriceItem(id: 1, name: "BTC", usdPrice: 123.45, eurPrice: 234.56)
        
        // Act
        let result = viewModel.getPriceText(priceItem)
        
        // Assert
        XCTAssertEqual(result, "USD: formatted_123.45 EUR: formatted_234.56")
    }
    
    func testGetPriceText_EUREnabled_NoEURPrice() {
        // Arrange
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        viewModel.showEURPrice = true
        let priceItem = MockPriceItem(id: 1, name: "BTC", usdPrice: 123.45, eurPrice: nil)
        
        // Act
        let result = viewModel.getPriceText(priceItem)
        
        // Assert
        XCTAssertEqual(result, "Price: formatted_123.45")
    }
    
    
    
    func testSetupFeatureFlags() async {
        // Arrange
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        
        // Act
        mockFeatureFlagProvider.update(flag: .supportEUR, newValue: true)
        await viewModel.refreshData()
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Assert
        XCTAssertTrue(viewModel.showEURPrice)
        
        // Act again
        mockFeatureFlagProvider.update(flag: .supportEUR, newValue: false)
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Assert again
        XCTAssertFalse(viewModel.showEURPrice)
    }
    
    
    func testRefreshData() async {
        // Arrange
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        
        let updatedItems = [
            MockPriceItem(id: 1, name: "BTC", usdPrice: 150.0, eurPrice: 135.0),
            MockPriceItem(id: 2, name: "ETH", usdPrice: 50.0, eurPrice: 45.0)
        ]
        mockUseCase.stubbedItems = updatedItems
        
        // Act - call the refreshData method
        await viewModel.refreshData()
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Assert - verify that the data was refreshed
        XCTAssertEqual(viewModel.displayItems.count, 2)
        XCTAssertEqual((viewModel.displayItems[0] as! MockPriceItem).name, "BTC")
        XCTAssertEqual((viewModel.displayItems[0] as! MockPriceItem).usdPrice, 150.0)
        XCTAssertEqual((viewModel.displayItems[1] as! MockPriceItem).name, "ETH")
    }
    
    // Test that refreshData correctly handles errors
    func testRefreshData_ErrorHandling() async {
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        
        mockUseCase.shouldThrowError = true
        
        
        await viewModel.refreshData()
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Assert - verify that the view model handled the error gracefully
        // The display items should be empty as the error handler sets allItems to empty array
        XCTAssertEqual(viewModel.displayItems.count, 0)
        
        // Test recovery after error
        mockUseCase.shouldThrowError = false
        mockUseCase.stubbedItems = [
            MockPriceItem(id: 1, name: "BTC", usdPrice: 200.0, eurPrice: 180.0),
            MockPriceItem(id: 2, name: "ETH", usdPrice: 50.0, eurPrice: 45.0)
        ]
        
        // Refresh again
        await viewModel.refreshData()
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Verify system recovers after error
        XCTAssertEqual(viewModel.displayItems.count, 2)
    }
    
    
    func testSearchFilter_EmptyQuery() async {
        // Arrange
        let expectedItems = [
            MockPriceItem(id: 1, name: "BTC", usdPrice: 100.0, eurPrice: 90.0),
            MockPriceItem(id: 2, name: "ETH", usdPrice: 50.0, eurPrice: 45.0)
        ]
        mockUseCase.stubbedItems = expectedItems
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        
        // Act
        viewModel.searchText = "B"
        viewModel.searchText = ""
        await viewModel.refreshData()
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Assert
        XCTAssertEqual(viewModel.displayItems.count, 2)
    }
    
    func testSearchFilter_WithMatchingQuery() async {
        // Arrange
        let expectedItems = [
            MockPriceItem(id: 1, name: "BTC", usdPrice: 100.0, eurPrice: 90.0),
            MockPriceItem(id: 2, name: "ETH", usdPrice: 50.0, eurPrice: 45.0),
            MockPriceItem(id: 3, name: "XRP", usdPrice: 25.0, eurPrice: 22.0)
        ]
        mockUseCase.stubbedItems = expectedItems
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        
        // Act
        viewModel.searchText = "B"
        viewModel.searchText = "BT"
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Assert
        XCTAssertEqual(viewModel.displayItems.count, 1)
        XCTAssertEqual((viewModel.displayItems[0] as! MockPriceItem).name, "BTC")
    }
    
    func testSearchFilter_WithNonMatchingQuery() async {
        // Arrange
        let expectedItems = [
            MockPriceItem(id: 1, name: "BTC", usdPrice: 100.0, eurPrice: 90.0),
            MockPriceItem(id: 2, name: "ETH", usdPrice: 50.0, eurPrice: 45.0)
        ]
        mockUseCase.stubbedItems = expectedItems
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        
        // Act
        viewModel.searchText = "X"
        try? await Task.sleep(nanoseconds: 300_000_000)
        viewModel.searchText = "XY"
        try? await Task.sleep(nanoseconds: 300_000_000)
        viewModel.searchText = "XYZ"
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Assert
        XCTAssertEqual(viewModel.displayItems.count, 0)
    }
    
    func testSearchFilter_CaseInsensitive() async {
        // Arrange
        let expectedItems = [
            MockPriceItem(id: 1, name: "BTC", usdPrice: 100.0, eurPrice: 90.0),
            MockPriceItem(id: 2, name: "ETH", usdPrice: 50.0, eurPrice: 45.0)
        ]
        mockUseCase.stubbedItems = expectedItems
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        
        // Act
        viewModel.searchText = "btc"  // lowercase search
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Assert
        XCTAssertEqual(viewModel.displayItems.count, 1)
        XCTAssertEqual((viewModel.displayItems[0] as! MockPriceItem).name, "BTC")
    }
    
    func testSearchBinding_ErrorHandling() async throws {
        // Arrange
        mockUseCase.shouldThrowError = true
        let viewModel = ListViewModel(dependencyProvider: mockDependencyProvider)
        
        // Act - trigger search which will cause an error
        viewModel.searchText = "BTC"
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Assert - verify that even with error, the UI doesn't crash
        // and the display items are empty (graceful error handling)
        XCTAssertTrue(viewModel.displayItems.isEmpty)
        
        // Now test recovery after error
        mockUseCase.shouldThrowError = false
        mockUseCase.stubbedItems = [
            MockPriceItem(id: 1, name: "BTC", usdPrice: 100.0, eurPrice: 90.0)
        ]
        
        // Trigger new search
        viewModel.searchText = "BT"
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(viewModel.displayItems.count, 1)
        // Verify system recovers after error
        
    }
    
    
}

final class MockFormatter: CryptoFormatter {
    override func format(value: Decimal, decimalPlaces: Int = 8) -> String {
        return "formatted_\(value)"
    }
}

struct MockPriceItem: CryptoPriceDataType {
    var id: Int
    var name: String
    var usdPrice: Decimal
    var eurPrice: Decimal?
}

class MockCryptoUseCase: CryptoUseCaseType {
    var stubbedItems: [CryptoPriceDataType] = []
    var shouldThrowError = false
    
    func getCryptoPriceData(supportEUR: Bool) async throws -> [CryptoPriceDataType] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 100, userInfo: nil)
        }
        return stubbedItems
    }
    
    func getCryptoPriceDataObservable(supportEUR: Bool) -> RxSwift.Single<[any CDC_Interview.CryptoPriceDataType]> {
        if shouldThrowError {
            return .error(NSError(domain: "TestError", code: 100, userInfo: nil))
        }
        return .just(stubbedItems)
    }
}


class MockDependencyProvider: ListViewModelDependencyProviderType {
    let useCase: CryptoUseCaseType?
    let featureFlagProvider: FeatureFlagProviderType?
    let cryptoFormatter: CryptoFormatter?
    
    init(useCase: CryptoUseCaseType?, featureFlagProvider: FeatureFlagProviderType?, cryptoFormatter: CryptoFormatter?) {
        self.useCase = useCase
        self.featureFlagProvider = featureFlagProvider
        self.cryptoFormatter = cryptoFormatter
    }
}


