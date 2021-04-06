//
//  MessageService.swift
//  EmailClient
//
//  Created by SV on 26/03/21.
//

import Foundation

class MessageService {
    typealias Handler = (GMailAPIService.Resource.Message?) -> Void
    typealias Message = GMailAPIService.Resource.Message

    private var messagesCache = NSCache<NSString, Message>()
    private var pendingHandlersFor = [String: [Handler]]()
    private let service: GMailAPIService
    private let queue = DispatchQueue(label: "messageservice.handlers")

    init(service: GMailAPIService) {
        self.service = service
    }
}

extension MessageService {
    func get(messageWithId messageId: String, completionHandler: @escaping Handler) {
        if let message = messagesCache.object(forKey: messageId as NSString) {
            return completionHandler(message)
        }
        appendHandler(formessageId: messageId, completionHandler)
        guard (pendingHandlersFor[messageId]?.count ?? 0) == 1 else {
            return
        }
        let path: GMailAPIService.Method.Path = .messages(.get(id: messageId))
        let method: GMailAPIService.Method = .init(pathParameters: path, queryParameters: nil)
        service.executeMethod(method, completionHandler: {
            [weak self]
            (messageOptional: Message?) in
            self?.queue.async {
                self?.handle(messageOptional, formessageId: messageId)
            }
        })
    }
}

extension MessageService {
    private func appendHandler(formessageId messageId: String, _ handler: @escaping Handler) {
        if pendingHandlersFor[messageId] == nil {
            pendingHandlersFor[messageId] = [Handler]()
        }
        pendingHandlersFor[messageId]?.append(handler)
    }

    private func handle(_ messageOptional: Message?, formessageId messageId: String) {
        let handlers = pendingHandlersFor[messageId]
        pendingHandlersFor[messageId] = []
        handlers?.forEach { $0(messageOptional) }
    }
}

extension MessageService {
    public func sendMessage(_ raw: String, completionHandler: @escaping (Message?) -> Void) {
        let path: GMailAPIService.Method.Path = .messages(.send)

        let json = """
        {
            \"raw\": \"\(raw)\"
        }
        """
        print(json)
        guard let body = json.data(using: .utf8) else {
            completionHandler(nil)
            return
        }

        let method = GMailAPIService.Method(pathParameters: path, queryParameters: nil, body: body)
        service.executeMethod(method) { (messageOpt: Message?) in
            completionHandler(messageOpt)
        }
    }
}
