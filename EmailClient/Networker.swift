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

typealias NetworkerResult<T> = Result<T, HttpError>

class Networker {
    static func request(_ request: URLRequest, completionHandler: @escaping (NetworkerResult<Data?>) -> Void) {
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            guard case .none = error else {
                return
            }
            print("response=", response)
            guard let data = data else {
                return
            }
            completionHandler(.success(data))
        }
        task.resume()
    }

    func fetch<T: Decodable>(fromURL url: URL, _ completionHandler: @escaping (NetworkerResult<T>) -> Void) {
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) {
            data, _, error in
            if let error = error {
                NSLog("\(error)")
                completionHandler(.failure(.badAccess))
                return
            }
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(T.self, from: data!)
                DispatchQueue.main.async {
                    completionHandler(.success(json))
                }
            } catch let e {
                print(T.self)
                print(e)
            }
        }
        task.resume()
    }

    static func fetch<T: Decodable>(fromRequest request: URLRequest, _ completionHandler: @escaping (NetworkerResult<T>) -> Void) {
        var request = request
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if let error = error {
                print(error)
                completionHandler(.failure(.badAccess))
                return
            }
            do {
                let decoder = JSONDecoder()
                let json = try decoder.decode(T.self, from: data!)
                print(json)

                DispatchQueue.main.async {
                    completionHandler(.success(json))
                }
                // print("Messages: ", list)
            } catch let e {
                print(T.self)
                print(response)
                print(e)
            }
        }
        task.resume()
    }
}
