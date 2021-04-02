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
    case httpError(HttpError)
}

typealias NetworkerResult = Result<Data?, NetworkerError>

enum Networker {
    typealias Handler = (NetworkerResult) -> Void
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 20
        let session = URLSession(configuration: config)
        return session
    }()

    static func fetch(fromRequest request: URLRequest, completionHandler: @escaping Handler) {
        let task = URLSession.shared.dataTask(with: request) {
            data, _, error in
            guard error == nil else {
                completionHandler(.failure(.httpError(.badAccess)))
                return
            }
            completionHandler(.success(data))
        }
        task.resume()
    }
}
