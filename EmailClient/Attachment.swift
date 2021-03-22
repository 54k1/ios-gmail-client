//
//  Attachment.swift
//  EmailClient
//
//  Created by SV on 22/03/21.
//

import Foundation
import QuickLook

class Attachment: NSObject {
    let url: URL
    let name: String
    let thumbnail: UIImage?
    
    init(withName name: String, withURL url: URL) {
        self.thumbnail = nil
        self.url = url
        self.name = name
        super.init()
        self.generateThumbnail(completionHandler: {_ in})
    }
}

extension Attachment: QLPreviewItem {
    var previewItemURL: URL? {
        url
    }
}

extension Attachment {
    func generateThumbnail(completionHandler: @escaping (UIImage?) -> Void) {
        guard thumbnail == nil else {
            completionHandler(thumbnail)
            return
        }
        let thumbnailSize = CGSize(width: 200, height: 200)
        let request = QLThumbnailGenerator.Request (fileAt: url, size: thumbnailSize, scale: 1.0, representationTypes: .all)
        
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request, completion: {
            rep, err in
            guard err == nil else {
                NSLog(err.debugDescription)
                completionHandler(nil)
                return
            }
            guard let rep = rep else {
                completionHandler(nil)
                return
            }
            completionHandler(rep.uiImage)
        })
    }
}
