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
    var accessToken: String = ""
    static var token = ""

    init(withAccessToken accessToken: String) {
        self.accessToken = accessToken
    }

    init() {}

    func setAccessToken(_ accessToken: String) {
        self.accessToken = accessToken
    }

    func fetch<T: Decodable>(fromURL url: URL, _ completionHandler: @escaping (NetworkerResult<T>) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(Networker.token)", forHTTPHeaderField: "Authorization")
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

    func fetch<T: Decodable>(fromRequest request: URLRequest, _ completionHandler: @escaping (NetworkerResult<T>) -> Void) {
        var request = request
        request.setValue("Bearer \(Networker.token)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) {
            data, _, error in
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
                print(e)
            }
        }
        task.resume()
    }
}
