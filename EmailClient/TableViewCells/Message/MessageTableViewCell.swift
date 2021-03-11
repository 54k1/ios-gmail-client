//
//  MessageTableViewCell.swift
//  EmailClient
//
//  Created by SV on 15/02/21.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
    static let identifier = "MessageTableViewCell"

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView()
        tableView.register(MessageBodyTableViewCell.self, forCellReuseIdentifier: MessageBodyTableViewCell.identifier)
        tableView.register(MessageHeaderTableViewCell.nib, forCellReuseIdentifier: MessageHeaderTableViewCell.identifier)
        tableView.register(MessageFooterTableViewCell.nib, forCellReuseIdentifier: MessageFooterTableViewCell.identifier)
        tableView.register(MessageAttachmentsTableViewCell.self, forCellReuseIdentifier: MessageAttachmentsTableViewCell.identifier)
        return tableView
    } ()
    
    private var message: UserMessage!
    private var heightAt = [IndexPath: CGFloat]()
    private var htmlString: String!
    private var attachments: [Attachment]!
    
    var delegate: ParentTableViewDelegate?
    var previewDelegate: PreviewDelegate?
    var indexPath: IndexPath?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .systemBlue
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = contentView.bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MessageTableViewCell: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (htmlString != nil) ? ((attachments == nil) ? 3 : 4) : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("MessageCell at \(indexPath)")
        let row = indexPath.row
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageHeaderTableViewCell.identifier, for: indexPath)
            heightAt[indexPath] = 44
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageBodyTableViewCell.identifier, for: indexPath) as! MessageBodyTableViewCell
            cell.delegate = self
            cell.indexPath = indexPath
            cell.configure(with: self.htmlString)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageFooterTableViewCell.identifier, for: indexPath)
            heightAt[indexPath] = 44
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageAttachmentsTableViewCell.identifier, for: indexPath) as! MessageAttachmentsTableViewCell
            cell.delegate = self
            cell.previewDelegate = previewDelegate
            cell.indexPath = indexPath
            cell.messageId = message.id
            cell.configure(with: self.attachments)
            // heightAt[indexPath] = 44
            return cell
        default:
            fatalError("Cell at indexPath: \(indexPath) does not exist")
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let ret = heightAt[indexPath] ?? 44.0
        return ret
    }
}

extension MessageTableViewCell {
    func configure(with message: UserMessage) {
        print("configure \(Self.description())")
        self.message = message
        self.extract(from: message)
        tableView.reloadData()
    }
    
    func extract(from message: UserMessage) {
        guard case let .success(component) = EmailClient.extract(message.payload!) else {
            // TODO: Render error popup
            print("failure")
            return
        }

        var alternative: Alternative!
        var htmlContent: Content!
        if let mixed = component as? Mixed {
            alternative = mixed.alternative
            if !mixed.attachments.isEmpty {
                self.attachments = mixed.attachments
            }
        } else if let alt = component as? Alternative {
            alternative = alt
        } else if let content = component as? Content {
            htmlContent = content
        } else {
            NSLog("Cant interpret mime")
            return
        }

        if htmlContent == nil {
            guard let content = alternative.contents.first(where: {
                content in
                content.mimeType == "text/html"
            }) else {
                // Expect htmlContent to be present
                print("no html")
                return
            }
            htmlContent = content
        }

        self.htmlString = "<html><head><meta charset='utf8'><meta name = 'viewport' content = 'width=device-width'></head>" + htmlContent.data + "</html>"
        print("set htmlString: \(htmlString)")
        
    }
}

extension MessageTableViewCell: ParentTableViewDelegate {
    func setHeight(to height: CGFloat, at indexPath: IndexPath) {
        heightAt[indexPath] = height
        let totalHeight = heightAt.values.reduce(0, {
            result, next in
            result+next
        })
        delegate?.setHeight(to:
        totalHeight, at: self.indexPath!)
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
