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
        tableView.register(MessageHeaderTableViewCell.self, forCellReuseIdentifier: MessageHeaderTableViewCell.identifier)
        tableView.register(MessageFooterTableViewCell.nib, forCellReuseIdentifier: MessageFooterTableViewCell.identifier)
        tableView.register(MessageAttachmentsTableViewCell.self, forCellReuseIdentifier: MessageAttachmentsTableViewCell.identifier)
        return tableView
    }()

    private var message: UserMessage!
    private var heightAt = [IndexPath: CGFloat]()
    private var htmlString: String!
    private var attachments: [Attachment]!

    weak var delegate: ParentTableViewDelegate?
    weak var previewDelegate: PreviewDelegate?
    var indexPath: IndexPath?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = contentView.bounds
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MessageTableViewCell: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        (htmlString != nil) ? ((attachments == nil) ? 3 : 4) : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        switch row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageHeaderTableViewCell.identifier, for: indexPath) as! MessageHeaderTableViewCell
            cell.configure(with: message)
            heightAt[indexPath] = 44
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageBodyTableViewCell.identifier, for: indexPath) as! MessageBodyTableViewCell
            cell.delegate = self
            cell.indexPath = indexPath
            cell.configure(with: htmlString)
            return cell
        case 2:
            // let cell = tableView.dequeueReusableCell(withIdentifier: MessageFooterTableViewCell.identifier, for: indexPath)
            heightAt[indexPath] = 44
            // return cell
            return UITableViewCell()
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageAttachmentsTableViewCell.identifier, for: indexPath) as! MessageAttachmentsTableViewCell
            cell.delegate = self
            cell.previewDelegate = previewDelegate
            cell.indexPath = indexPath
            cell.messageId = message.id
            cell.configure(with: attachments)
            // heightAt[indexPath] = 44
            return cell
        default:
            fatalError("Cell at indexPath: \(indexPath) does not exist")
        }
    }

    func numberOfSections(in _: UITableView) -> Int {
        1
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let ret = heightAt[indexPath] ?? 44.0
        return ret
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MessageTableViewCell {
    func configure(with message: UserMessage) {
        self.message = message
        extract(from: message)
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
                attachments = mixed.attachments
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

        htmlString = "<html><head><meta charset='utf8'><meta name = 'viewport' content = 'width=device-width'></head>" + htmlContent.data + "</html>"
    }
}

extension MessageTableViewCell: ParentTableViewDelegate {
    func setHeight(to height: CGFloat, at indexPath: IndexPath) {
        heightAt[indexPath] = height
        let totalHeight = heightAt.values.reduce(0) {
            result, next in
            result + next
        }
        delegate?.setHeight(to:
            totalHeight, at: self.indexPath!)
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
