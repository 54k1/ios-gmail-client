//
//  AttachmentService.swift
//  EmailClient
//
//  Created by SV on 30/03/21.
//

import Foundation
import GoogleAPIClientForREST
import QuickLook

class AttachmentService {
    typealias Handler = (URL?) -> Void

    init(service: GMailAPIService) {
        self.service = service
    }

    // MARK: Private

    private let service: GMailAPIService
    private let cache: NSCache<NSString, NSURL> = NSCache()
    private var pendingHandlersFor = [String: [Handler]]()
    private let queue = DispatchQueue(label: "attachmentservice.handlers")
}

// MARK: Handlers

extension AttachmentService {
    private func appendHandler(forKey key: String, _ handler: @escaping Handler) {
        if pendingHandlersFor[key] == nil {
            pendingHandlersFor[key] = []
        }
        pendingHandlersFor[key]?.append(handler)
    }

    private func handle(_ url: URL?, forKey key: String) {
        let handlers = pendingHandlersFor[key]
        pendingHandlersFor[key] = []
        handlers?.forEach { $0(url) }
    }
}

extension AttachmentService {
    private func generateKey(for attachment: AttachmentMO) -> NSString {
        (attachment.messageId + attachment.id) as NSString
    }

    public func fetchAttachmentContents(attachment: AttachmentMO, completionHandler: @escaping Handler) {
        let (messageId, attachmentId) = (attachment.messageId, attachment.id)
        let url = existingFile(withName: attachment.filename)
        guard attachment.location == nil, url == nil else {
            // let url = URL(string: attachment.location!)
            let url = url?.appendingPathComponent(attachment.filename)
            completionHandler(url! as URL)
            return
        }
        let key = generateKey(for: attachment)

        appendHandler(forKey: key as String, completionHandler)

        guard (pendingHandlersFor[key as String]!.count) == 1 else { return }

        let path: GMailAPIService.Method.Path = .messages(.attachments(messageId: messageId, attachmentId: attachmentId))
        let method: GMailAPIService.Method = .init(pathParameters: path, queryParameters: nil)

        service.executeMethod(method) {
            [weak self]
            (messagePartBodyOptional: GMailAPIService.Resource.Message.Part.Body?) in

            var url: URL?
            if let messagePartBody = messagePartBodyOptional {
                if let contents = decodeBody(messagePartBody) {
                    url = storeAttachment(withData: contents, withFilename: attachment.filename)
                }
            }

            self?.queue.async {
                self?.handle(url, forKey: key as String)
            }
        }
    }
}

extension AttachmentService {
    private func cacheGet(_ key: NSString) -> NSURL? {
        cache.object(forKey: key)
    }

    private func cachePut(_ value: NSURL, forKey key: NSString) {
        cache.setObject(value, forKey: key)
    }
}

private func storeAttachment(withData data: Data, withFilename filename: String) -> URL? {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
    print("URL=", url)
    do {
        try data.write(to: url)
        return url
    } catch let err {
        print(err)
        return nil
    }
}

private func decodeBody(_ body: GMailAPIService.Resource.Message.Part.Body) -> Data? {
    guard let data = body.data else { return nil }
    return GTLRDecodeWebSafeBase64(data)
}

private func generateThumbnail(for url: URL, attachment: AttachmentMO) {
    let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: 100, height: 100), scale: 1.0, representationTypes: .all)

    QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, err in
        if let err = err {
            print("Thumbnail Generation Error", err)
        }
        attachment.thumbnail = rep?.uiImage.pngData()
    }
}

private func existingFile(withName name: String) -> NSURL? {
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    let url = NSURL(fileURLWithPath: path)
    if let pathComponent = url.appendingPathComponent(name) {
        let filePath = pathComponent.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            return url
        } else {
            return nil
        }
    } else {
        return nil
    }
}
