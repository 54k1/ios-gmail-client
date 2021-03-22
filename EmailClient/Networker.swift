//
//  Networker.swift
//  EmailClient
//
//  Created by SV on 11/02/21.
//

import Foundation

enum HttpError: Error {
    case badAccess
}

enum NetworkerError: Error {
    case jsonDecodingError
    case httpError(HttpError)
}

typealias NetworkerResult<T> = Result<T, NetworkerError>

class Networker {
    typealias Handler<T> = (NetworkerResult<T>) -> Void

    /// Fetch data and decode into object
    func fetch<T: Decodable>(fromURL url: URL, completionHandler: @escaping Handler<T>) {
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) {
            data, _, error in
            if let error = error {
                NSLog("\(error)")
                completionHandler(.failure(.httpError(.badAccess)))
                return
            }
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(T.self, from: data!)
                completionHandler(.success(json))
            } catch {
                completionHandler(.failure(.jsonDecodingError))
            }
        }
        task.resume()
    }

    /// Fetch data and decode into object
    static func fetch<T: Decodable>(fromRequest request: URLRequest, completionHandler: @escaping Handler<T>) {
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if let error = error {
                completionHandler(.failure(.httpError(.badAccess)))
                return
            }
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(T.self, from: data!)

                completionHandler(.success(json))
            } catch let e {
                let x = String(describing: T.self)
                completionHandler(.failure(.jsonDecodingError))
            }
        }
        task.resume()
    }
}
