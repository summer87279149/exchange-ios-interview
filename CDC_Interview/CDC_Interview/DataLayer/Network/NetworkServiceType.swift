import Foundation
import RxSwift

protocol NetworkServiceType {
    func loadLocalJSONObservable<T: Decodable>(filename: String) -> Single<T>
}

final class NetworkService: NetworkServiceType {
    func loadLocalJSONObservable<T: Decodable>(filename: String) -> Single<T> {
        return Single.create { single in
            // Create a background task that can be cancelled
            let task = Task {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    if Task.isCancelled {
                        return
                    }
                    
                    guard let path = Bundle.main.path(forResource: filename, ofType: "json") else {
                        single(.failure(NetworkError.fileNotFound(filename: filename)))
                        return
                    }
                    
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
                    
                    if !Task.isCancelled {
                        single(.success(decodedObject))
                    }
                } catch let error as DecodingError {
                    if !Task.isCancelled {
                        single(.failure(NetworkError.decodingFailed(error: error)))
                    }
                } catch {
                    if !Task.isCancelled {
                        single(.failure(NetworkError.unknown(error: error)))
                    }
                }
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}

enum NetworkError: Error {
    case fileNotFound(filename: String)
    case decodingFailed(error: DecodingError)
    case unknown(error: Error)
} 
