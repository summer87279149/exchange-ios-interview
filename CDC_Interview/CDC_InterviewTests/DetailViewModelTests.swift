import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import CDC_Interview

final class DetailViewModelTests: XCTestCase {
    private var mockDependencyProvider: MockDetailDependencyProvider!
    private var mockFormatter: MockFormatter!
    private var featureFlagProvider: FeatureFlagProvider!
    private var mockItem: MockPriceItem!
    private var disposeBag: DisposeBag!
    
    override func setUpWithError() throws {
        mockFormatter = MockFormatter()
        featureFlagProvider = FeatureFlagProvider()
        mockDependencyProvider = MockDetailDependencyProvider(
            formatter: mockFormatter,
            featureFlagProvider: featureFlagProvider
        )
        mockItem = MockPriceItem(id: 1, name: "BTC", usdPrice: 50000, eurPrice: 45000)
        disposeBag = DisposeBag()
    }
    
    override func tearDownWithError() throws {
        mockDependencyProvider = nil
        mockFormatter = nil
        featureFlagProvider = nil
        mockItem = nil
        disposeBag = nil
    }
    
    func testInitialization() {
        // Arrange
        featureFlagProvider.update(flag: .supportEUR, newValue: true)
        
        // Act
        let viewModel = DetailViewModel(item: mockItem, dependencyProvider: mockDependencyProvider)
        
        // Assert
        XCTAssertTrue(viewModel.showEURPrice)
    }
    
    func testFormattedUSDPrice() {
        // Arrange
        let viewModel = DetailViewModel(item: mockItem, dependencyProvider: mockDependencyProvider)
        
        // Act
        let formattedPrice = viewModel.formattedUSDPrice
        
        // Assert
        XCTAssertEqual(formattedPrice, "formatted_50000")
    }
    
    func testFormattedEURPrice_WithEURValue() {
        // Arrange
        let viewModel = DetailViewModel(item: mockItem, dependencyProvider: mockDependencyProvider)
        
        // Act
        let formattedPrice = viewModel.formattedEURPrice
        
        // Assert
        XCTAssertEqual(formattedPrice, "formatted_45000")
    }
    
    func testFormattedEURPrice_WithoutEURValue() {
        // Arrange
        let itemWithoutEUR = MockPriceItem(id: 1, name: "BTC", usdPrice: 50000, eurPrice: nil)
        let viewModel = DetailViewModel(item: itemWithoutEUR, dependencyProvider: mockDependencyProvider)
        
        // Act
        let formattedPrice = viewModel.formattedEURPrice
        
        // Assert
        XCTAssertEqual(formattedPrice, "--")
    }
    
    func testFeatureFlagChanges() {
        // Arrange
        featureFlagProvider.update(flag: .supportEUR, newValue: false)
        let viewModel = DetailViewModel(item: mockItem, dependencyProvider: mockDependencyProvider)
        
        // Initial state
        XCTAssertFalse(viewModel.showEURPrice)
        
        // Act - change flag to true
        featureFlagProvider.update(flag: .supportEUR, newValue: true)
        // Assert
        XCTAssertTrue(viewModel.showEURPrice)
        
        // Act - change flag back to false
        featureFlagProvider.update(flag: .supportEUR, newValue: false)
        // Assert
        XCTAssertFalse(viewModel.showEURPrice)
    }
}

// MARK: - Test Helpers

class MockDetailDependencyProvider: ListViewModelDependencyProviderType {
    let cryptoFormatter: CryptoFormatter?
    let featureFlagProvider: FeatureFlagProviderType?
    
    var useCase: CryptoUseCaseType? {
        fatalError("UseCase should not be used in DetailViewModel tests")
    }
    
    init(formatter: CryptoFormatter, featureFlagProvider: FeatureFlagProviderType) {
        self.cryptoFormatter = formatter
        self.featureFlagProvider = featureFlagProvider
    }
}

