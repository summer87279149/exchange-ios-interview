import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import CDC_Interview

final class SettingViewModelTests: XCTestCase {
    
    private var mockDependencyProvider: MockSettingDependencyProvider!
    private var featureFlagProvider: FeatureFlagProvider!
    private var disposeBag: DisposeBag!
    
    override func setUpWithError() throws {
        featureFlagProvider = FeatureFlagProvider()
        mockDependencyProvider = MockSettingDependencyProvider(featureFlagProvider: featureFlagProvider)
        disposeBag = DisposeBag()
    }
    
    override func tearDownWithError() throws {
        mockDependencyProvider = nil
        featureFlagProvider = nil
        disposeBag = nil
    }
    
    func testInitialization_WithFlagTrue() {
        // Arrange
        featureFlagProvider.update(flag: .supportEUR, newValue: true)
        
        // Act
        let viewModel = SettingViewModel(dependencyProvider: mockDependencyProvider)
        
        // Assert
        XCTAssertTrue(viewModel.supportEUR)
    }
    
    func testInitialization_WithFlagFalse() {
        // Arrange
        featureFlagProvider.update(flag: .supportEUR, newValue: false)
        
        // Act
        let viewModel = SettingViewModel(dependencyProvider: mockDependencyProvider)
        
        // Assert
        XCTAssertFalse(viewModel.supportEUR)
    }
    
    func testUpdateSupportEUR_UpdatesFeatureFlag() {
        // Arrange
        featureFlagProvider.update(flag: .supportEUR, newValue: false)
        let viewModel = SettingViewModel(dependencyProvider: mockDependencyProvider)
        
        // Act
        viewModel.supportEUR = true
        
        // Assert
        XCTAssertTrue(featureFlagProvider.getValue(flag: .supportEUR))
        
        // Act again
        viewModel.supportEUR = false
        
        // Assert again
        XCTAssertFalse(featureFlagProvider.getValue(flag: .supportEUR))
    }
    
    func testInitialization_WithNilFeatureFlagProvider() {
        // Arrange
        let nilProviderDependency = MockSettingDependencyProvider(featureFlagProvider: nil)
        
        // Act
        let viewModel = SettingViewModel(dependencyProvider: nilProviderDependency)
        
        // Assert
        XCTAssertFalse(viewModel.supportEUR)
    }
}

// MARK: - Test Helpers

class MockSettingDependencyProvider: ListViewModelDependencyProviderType {
    var useCase: CryptoUseCaseType? {
        return nil
    }
    
    var featureFlagProvider: FeatureFlagProviderType?
    
    var cryptoFormatter: CryptoFormatter? {
        return nil
    }
    
    init(featureFlagProvider: FeatureFlagProviderType?) {
        self.featureFlagProvider = featureFlagProvider
    }
}
