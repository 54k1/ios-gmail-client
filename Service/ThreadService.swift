//
//  ThreadService.swift
//  EmailClient
//
//  Created by SV on 26/03/21.
//

import Foundation

class ThreadService {
    typealias Handler = (GMailAPIService.Resource.Thread?) -> Void
    private typealias Thread = GMailAPIService.Resource.Thread

    private var threadsCache = NSCache<NSString, Thread>()
    private var pendingHandlersFor = [String: [Handler]]()
    private let service: GMailAPIService
    private let queue = DispatchQueue(label: "threadservice.handlers")

    init(service: GMailAPIService) {
        self.service = service
    }
}

extension ThreadService {
    func get(threadWithId threadId: String, completionHandler: @escaping Handler) {
        if let thread = threadsCache.object(forKey: threadId as NSString) {
            return completionHandler(thread)
        }
        appendHandler(forThreadId: threadId, completionHandler)
        guard (pendingHandlersFor[threadId]!.count) == 1 else {
            return
        }
        let path: GMailAPIService.Method.Path = .threads(.get(userId: "me", id: threadId))
        let method: GMailAPIService.Method = .init(pathParameters: path, queryParameters: nil)
        service.executeMethod(method, completionHandler: {
            [weak self]
            (threadOptional: Thread?) in
            self?.queue.async {
                self?.handle(threadOptional, forThreadId: threadId)
            }
        })
    }
}

extension ThreadService {
    private func appendHandler(forThreadId threadId: String, _ handler: @escaping Handler) {
        if pendingHandlersFor[threadId] == nil {
            pendingHandlersFor[threadId] = []
        }
        pendingHandlersFor[threadId]?.append(handler)
    }

    private func handle(_ threadOptional: Thread?, forThreadId threadId: String) {
        let handlers = pendingHandlersFor[threadId]
        pendingHandlersFor[threadId] = []
        handlers?.forEach { $0(threadOptional) }
    }
}
