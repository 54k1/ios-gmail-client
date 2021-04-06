//
//  GMailAPIService.swift
//  EmailClient
//
//  Created by SV on 20/03/21.
//

import Foundation

class GMailAPIService {
    let authorizationValue: String
    init(withAuthorizationValue authorizationValue: String) {
        self.authorizationValue = "Bearer \(authorizationValue)"
    }

    enum Resource {}
}

extension GMailAPIService {
    struct Method {
        let pathParameters: Path
        let queryParameters: QueryParameters?
        let body: Data?

        init(pathParameters: Path, queryParameters: QueryParameters? = nil, body: Data? = nil) {
            self.pathParameters = pathParameters
            self.queryParameters = queryParameters
            self.body = body
        }
    }

    func executeMethod<T: Codable>(_ method: Method, completionHandler: @escaping (T?) -> Void) {
        let request = makeRequest(forMethod: method)
        Networker.fetch(fromRequest: request, completionHandler: {
            (result: NetworkerResult) in
            guard case let .success(dataOptional) = result, let data = dataOptional else {
                completionHandler(nil)
                return
            }
            let decoder = JSONDecoder()
            do {
                let object = try decoder.decode(T.self, from: data)
                completionHandler(object)
            } catch let e {
                print(e)
                completionHandler(nil)
            }
        })
    }
}

extension GMailAPIService {
    private func makeRequest(forMethod method: Method) -> URLRequest {
        makeRequest(forPath: method.pathParameters, withQueryParameters: method.queryParameters, withBody: method.body)
    }

    private func makeRequest(forPath path: Method.Path, withQueryParameters queryParameters: Method.QueryParameters?, withBody body: Data?) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "gmail.googleapis.com"
        urlComponents.path = "/gmail/v1/users/me\(path.toString())"

        urlComponents.queryItems = queryParameters?.compactMap { (key: String, value: String) -> URLQueryItem in
            URLQueryItem(name: key, value: value)
        }

        var request = makeRequest(url: urlComponents.url!)
        if body != nil {
            request.httpBody = body
            request.httpMethod = "POST"
            request.addValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private var authorizationField: String {
        "Authorization"
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue(authorizationValue, forHTTPHeaderField: authorizationField)
        return request
    }
}

extension GMailAPIService.Method {
    typealias QueryParameters = [String: String]

    enum Path {
        case threads(ThreadPath)
        case messages(MessagePath)
        case labels(LabelPath)
        case history(HistoryPath)
        case users(UserPath)

        enum ThreadPath {
            case list(userId: String, pageToken: String?)
            case get(userId: String, id: String)
        }

        enum MessagePath {
            enum AttachmentPath {
                case get(id: String)
            }

            case get(id: String)
            case attachments(messageId: String, attachmentId: String)
            case send
        }

        enum LabelPath {
            case get(id: String)
            case list
        }

        enum HistoryPath {
            case list
        }

        enum UserPath: String {
            case getProfile = "profile"
        }
    }
}

private extension GMailAPIService.Method.Path {
    func toString() -> String {
        var method = "/"
        switch self {
        case let .threads(threadPath):
            method += "threads"
            switch threadPath {
            case let .get(_, id):
                method += "/\(id)"
            case .list:
                method += ""
            }
        case let .messages(messagePath):
            method += "messages"
            switch messagePath {
            case let .attachments(messageId, attachmentId):
                method += "/\(messageId)/attachments/\(attachmentId)"
            case let .get(id):
                method += "/\(id)"
            case .send:
                method += "/send"
            }
        case let .labels(labelPath):
            method += "labels"
            switch labelPath {
            case let .get(id):
                method += "/\(id)"
            case .list:
                ()
            }
        case let .history(path):
            method += "history"
            switch path {
            case .list:
                ()
            }
        case let .users(path):
            method += path.rawValue
        }
        return method
    }
}
