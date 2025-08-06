# Original Project Issues and Solutions

1. **Inconsistent Architecture**: The project mixed MVVM and dependency injection, but with unclear layer boundaries. ViewModel directly referenced UseCase, causing coupling and testing difficulties.
   - **Solution**: Refactored to clear MVVM architecture, introduced `ListViewModelDependencyProviderType` protocol as an abstraction layer, making ViewModels interact with UseCases through protocols instead of concrete implementations. This reduced coupling and improved testability.

2. **Overuse of Singleton Pattern**: Excessive use of singletons (shared instances) for UseCase and CryptoFormatter made testing difficult and created tight coupling between components.
   - **Solution**: Provided component instances through containers, reducing singleton dependency. Created protocol interfaces for all services to allow mock implementations during testing. While singletons are convenient, overuse makes global state hard to manage and test.

3. **Mixed UI Frameworks**: The project mixed SwiftUI and UIKit without a clear navigation strategy, only using UIHostingController as a bridge.
   - **Solution**: Clearly adopted "UIKit as container, SwiftUI as view" strategy, using coordinator pattern to let UIKit handle navigation, ensuring consistent user experience.

4. **Spelling Errors in API**: FeatureFlagProvider used "falg" instead of "flag" parameter names in multiple methods.
   - **Solution**: Fixed all spelling errors in APIs.

5. **Lack of Error Handling**: Code used force unwrapping (!) in many places.
   - **Solution**: Used optional chaining (?) when possible, only using force unwrapping (!) when clearly safe.

6. **Incomplete Dependency Injection**: DI container didn't handle all dependencies consistently. For example, CryptoFormatter was directly held by Views instead of being injected through the container. Also, it wasn't thread-safe.
   - **Solution**: Improved dependency injection container to ensure all components are provided through it, added thread safety using NSLock, and unified dependency management.

7. **No Unit Tests**: Despite having a CDC_InterviewTests directory, unit tests couldn't pass.
   - **Solution**: Added comprehensive unit tests, including ListViewModel and DetailViewModel tests, using mock objects to replace real dependencies and verify core functionality.

8. **Inconsistent Data Models**: USDPrice and AllPrice had different structures, making switching difficult when feature flags changed.
   - **Solution**: Unified data model interfaces through CryptoPriceDataType protocol, allowing different data source models to be handled consistently, simplifying feature flag switching logic.

9. **Hardcoded Values**: File paths and mock delays were hardcoded rather than configurable.
   - **Solution**: For this test project, kept some hardcoded values, but in real applications, configuration files or environment variables should be used.

10. **Missing Network Layer**: The app simulated API calls by reading JSON files but lacked a network abstraction layer needed in real applications.
    - **Solution**: Added NetworkServiceType protocol and implementation as a simple network layer.

11. **Not Using Protocol-Based Design**: Code didn't use protocols as interfaces, making it difficult to mock components in tests.
    - **Solution**: Introduced protocols to define interfaces for all major components like CryptoUseCaseType, NetworkServiceType, FeatureFlagProviderType, and ListViewModelDependencyProviderType, improving system testability and flexibility. Protocol-first design is recommended in Swift for dependency injection and unit testing.

12. **No Search Functionality**
    - **Solution**: Implemented search using RxSwift. Added debouncing to prevent excessive API calls during rapid typing. Used combineLatest to combine search text and data items for filtering. Used flatMapLatest operator to handle search requests, ensuring only the latest search request is processed when users type quickly, preventing "race condition" issues.




