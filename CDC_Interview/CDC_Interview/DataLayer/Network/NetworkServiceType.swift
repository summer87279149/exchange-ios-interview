import Foundation
import RxSwift

protocol NetworkServiceType {
    func loadLocalJSON<T: Decodable>(filename: String) async throws -> T
    func loadLocalJSONObservable<T: Decodable>(filename: String) -> Observable<T>
}

class NetworkService: NetworkServiceType {
    func loadLocalJSON<T: Decodable>(filename: String) async throws -> T {
        guard let path = Bundle.main.path(forResource: filename, ofType: "json") else {
            throw NetworkError.fileNotFound(filename: filename)
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            if let decodingError = error as? DecodingError {
                throw NetworkError.decodingFailed(error: decodingError)
            } else {
                throw NetworkError.unknown(error: error)
            }
        }
    }
    
    func loadLocalJSONObservable<T: Decodable>(filename: String) -> Observable<T> {
        return Observable.create { observer in
            guard let path = Bundle.main.path(forResource: filename, ofType: "json") else {
                observer.onError(NetworkError.fileNotFound(filename: filename))
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                observer.onNext(decodedObject)
                observer.onCompleted()
            } catch let error as DecodingError {
                observer.onError(NetworkError.decodingFailed(error: error))
                observer.onCompleted()
            } catch {
                observer.onError(NetworkError.unknown(error: error))
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}

enum NetworkError: Error {
    case fileNotFound(filename: String)
    case decodingFailed(error: DecodingError)
    case unknown(error: Error)
} 