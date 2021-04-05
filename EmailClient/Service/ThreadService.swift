//
//  ThreadService.swift
//  EmailClient
//
//  Created by SV on 26/03/21.
//

import Foundation

class ThreadService {
    typealias Thread = GMailAPIService.Resource.Thread
    typealias Handler = (Thread?) -> Void
    typealias ListResponseHandler = (GMailAPIService.Resource.ThreadListResponse?) -> Void

    private var threadsCache = NSCache<NSString, Thread>()
    private var pendingHandlersFor = [String: [Handler]]()
    private let service: GMailAPIService
    private let queue = DispatchQueue(label: "threadservice.handlers")

    init(service: GMailAPIService) {
        self.service = service
    }
}

// MARK: Handlers

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

extension ThreadService {
    // MARK: Get Thread

    func get(threadWithId threadId: String, completionHandler: @escaping Handler) {
        if let thread = threadsCache.object(forKey: threadId as NSString) {
            return completionHandler(thread)
        }

        appendHandler(forThreadId: threadId, completionHandler)
        guard (pendingHandlersFor[threadId]!.count) == 1 else { return }

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

    // MARK: List Threads

    func list(withLabelId labelId: String?, withMaxResults maxResults: Int, withPageToken pageToken: String?, completionHandler: @escaping ListResponseHandler) {
        let path: GMailAPIService.Method.Path = .threads(.list(userId: "me", pageToken: pageToken ?? ""))
        var queryParameters = [
            "maxResults": String(maxResults),
        ]
        if let labelId = labelId {
            queryParameters["labelIds"] = labelId
        } else {
            queryParameters["includeSpamTrash"] = "TRUE"
        }
        let method = GMailAPIService.Method(pathParameters: path, queryParameters: queryParameters)
        service.executeMethod(method, completionHandler: {
            (threadList: GMailAPIService.Resource.ThreadListResponse?) in
            completionHandler(threadList)
        })
    }

    // MARK: List Thread Detail

    func listDetail(forLabelId labelId: String?, withMaxResults maxResults: Int, withPageToken pageToken: String?, completionHandler: @escaping ListResponseHandler) {
        list(withLabelId: labelId, withMaxResults: maxResults, withPageToken: pageToken) {
            threadListResponse in
            guard let threads = threadListResponse?.threads else {
                completionHandler(nil)
                return
            }
            let group = DispatchGroup()

            var threadWithId = [String: Thread]()
            threads.forEach {
                group.enter()
                self.get(threadWithId: $0.id, completionHandler: {
                    thread in
                    defer {
                        group.leave()
                    }
                    guard let thread = thread else {
                        return
                    }
                    threadWithId[thread.id] = thread
                })
            }

            group.notify(queue: DispatchQueue.global()) {
                threadListResponse?.threads = threadListResponse?.threads?.compactMap {
                    threadWithId[$0.id]
                }
                completionHandler(threadListResponse)
            }
        }
    }
}
