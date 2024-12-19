//
//  MessageModels.swift
//  Mailosaur
//
//  Created by Mailosaur on 20.01.2023.
//

import Foundation

public struct Message: Decodable {
    /// Gets or sets unique identifier for the message.
    public let id: String
    /// Gets or sets the type of message.
    public let type: String
    /// Gets or sets the sender of the message.
    public let from: [MessageAddress]
    /// Gets or sets the message’s recipient.
    public let to: [MessageAddress]
    /// Gets or sets carbon-copied recipients for email messages.
    public let cc: [MessageAddress]
    /// Gets or sets blind carbon-copied recipients for email messages.
    public let bcc: [MessageAddress]
    /// Gets or sets the datetime that this message was received by Mailosaur
    public let received: Date
    /// Gets or sets the message’s subject.
    public let subject: String
    /// Gets or sets message content that was sent in HTML format.
    public let html: MessageContent
    /// Gets or sets message content that was sent in plain text format.
    public let text: MessageContent
    /// Gets or sets an array of attachment metadata for any attached files
    public let attachments: [MessageAttachment]
    public let metadata: MessageMetadata
    /// Gets or sets identifier for the server in which the message is located
    public let server: String
}

public struct MessageAddress: Decodable {
    /// Gets or sets display name, if one is specified.
    public let name: String?
    /// Gets or sets email address (applicable to email messages).
    public let email: String?
    /// Gets or sets phone number (applicable to SMS messages).
    public let phone: String?
}

public struct MessageContent: Decodable {
    public let links: [MessageLink]
    public let codes: [MessageCode]
    public let images: [MessageImage]?
    public let body: String?
}

public struct MessageLink: Decodable {
    public let href: String
    public let text: String?
}

public struct MessageImage: Decodable {
    public let src: String
    public let alt: String
}

public struct MessageCode: Decodable {
    public let value: String
}

public struct MessageAttachment: Codable {
    public let id: String
    public let contentType: String
    public let fileName: String
    public let contentId: String?
    public let length: Int?
    public let url: String
}

public struct MessageAttachmentOptions: Codable {
    public let contentType: String
    public let fileName: String
    public let content: String
}

public struct MessageMetadata: Decodable {
    /// Gets or sets email headers.
    public let headers: [MessageHeader]
    /// TBC
    public let ehlo: String?
    /// TBC
    public let mailFrom: String?
    /// Gets or sets the rcpt value of the message.
    public let rcptTo: [MessageAddress]
}

public struct MessageHeader: Decodable {
    /// Gets or sets header key.
    public let field: String
    /// Gets or sets header value.
    public let value: String
}

public struct MessageListResult: Decodable {
    /// Gets or sets the individual summaries of each message forming the
    /// result. Summaries are returned sorted by received date, with the
    /// most recently-received messages appearing first.
    public let items: [MessageSummary]
}

struct MessageListResultWithHeaders: Decodable {
    public let messageListResult: MessageListResult
    public let delayHeader: String
}

public struct MessageSummary: Decodable {
    /// Gets or sets unique identifier for the message.
    public let id: String
    /// Gets or sets the type of message.
    public let type: String
    /// Gets or sets the sender of the message.
    public let from: [MessageAddress]
    /// Gets or sets the message’s recipient.
    public let to: [MessageAddress]
    /// Gets or sets carbon-copied recipients for email messages.
    public let cc: [MessageAddress]
    /// Gets or sets blind carbon-copied recipients for email messages.
    public let bcc: [MessageAddress]
    /// Gets or sets the datetime that this message was received by Mailosaur
    public let received: Date
    /// Gets or sets the message’s subject.
    public let subject: String
    /// Summary snippet taken from message body
    public let summary: String
    /// Gets or sets identifier for the server in which the message is lcoated
    public let server: String
    /// Number of message attachments
    public let attachments: Int?
}

public struct MessageSearchCriteria: Encodable {
    /// Gets or sets the full email address from which the target email was sent
    public let sentFrom: String?
    /// Gets or sets the full email address to which the target email was sent
    public let sentTo: String?
    /// Gets or sets the value to seek within the target email's subject line
    public let subject: String?
    /// Gets or sets the value to seek within the target email's HTML or text body
    public let body: String?
    /// If set to ALL (default), then only results that match all
    /// specified criteria will be returned. If set to ANY, results that match any of the
    /// specified criteria will be returned.
    public let match: MessageSearchMatchOperator
    
    public init(sentFrom: String? = nil, sentTo: String? = nil, subject: String? = nil, body: String? = nil, match: MessageSearchMatchOperator = .all) {
        self.sentFrom = sentFrom
        self.sentTo = sentTo
        self.subject = subject
        self.body = body
        self.match = match
    }
}

public enum MessageSearchMatchOperator: String, Encodable {
    case all = "ALL"
    case any = "ANY"
}

public struct MessageCreateOptions: Encodable {
    /// The email address to which the email will be sent.
    public let to: String
    /// The email address to which the email will be CC'd.
    public let cc: String?
    /// If true, email will be sent upon creation.
    public let send: Bool
    /// The email subject line.
    public let subject: String
    /// The plain text body of the email. Note that only text or html can be supplied, not both.
    public let text: String?
    /// The HTML body of the email. Note that only text or html can be supplied, not both.
    public let html: String?
    /// Any message attachments.
    public let attachments: [MessageAttachmentOptions]?
    
    /// Initializes a new instance of the MessageCreateOptions class.
    ///  - Important: Note that only html or text can be supplied, not both.
    ///  - Parameter to: The email address to which the email will be sent.
    ///  - Parameter send: If true, email will be sent upon creation.
    ///  - Parameter subject: The email subject line.
    ///  - Parameter text: Any additional plain text content to include in the reply. Note that only text or html can be supplied, not both
    ///  - Parameter html: Any additional HTML content to include in the reply. Note that only html or text can be supplied, not both.
    ///  - Parameter attachments: Any message attachments.
    ///  - Parameter cc: The email address to which the email will be CC'd.
    public init(to: String, send: Bool, subject: String, text: String? = nil, html: String? = nil, attachments: [MessageAttachmentOptions]? = nil, cc: String? = nil) {
        self.to = to
        self.cc = cc
        self.send = send
        self.subject = subject
        self.text = text
        self.html = html
        self.attachments = attachments
    }
}

public struct MessageForwardOptions: Encodable {
    /// The email address to which the email will be sent.
    public let to: String
    /// The email address to which the email will be CC'd.
    public let cc: String?
    // Any additional plain text content to forward the email with. Note that only text or html can be supplied, not both.
    public let text: String?
    /// Any additional HTML content to forward the email with. Note that only html or text can be supplied, not both.
    public let html: String?
    
    /// Initializes a new instance of the MessageForwardOptions class.
    ///  - Important: Note that only html or text can be supplied, not both.
    ///  - Parameter to: The email address to which the email will be sent.
    ///  - Parameter cc: The email address to which the email will be sent.
    ///  - Parameter text: Any additional plain text content to include in the reply. Note that only text or html can be supplied, not both
    ///  - Parameter html: Any additional HTML content to include in the reply. Note that only html or text can be supplied, not both.
    public init(to: String, text: String? = nil, html: String? = nil, cc: String? = nil) {
        self.to = to
        self.cc = cc
        self.text = text
        self.html = html
    }
}

public struct MessageReplyOptions: Encodable {
    /// The email address to which the email will be CC'd.
    public let cc: String?
    /// Any additional plain text content to include in the reply. Note that only text or html can be supplied, not both.
    public let text: String?
    /// Any additional HTML content to include in the reply. Note that only html or text can be supplied, not both.
    public let html: String?
    /// Any message attachments.
    public let attachments: [MessageAttachmentOptions]?
    
    
    ///  Initializes a new instance of the MessageReplyOptions class.
    ///  - Important: Note that only html or text can be supplied, not both.
    ///  - Parameter text: Any additional plain text content to include in the reply. Note that only text or html can be supplied, not both
    ///  - Parameter html: Any additional HTML content to include in the reply. Note that only html or text can be supplied, not both.
    ///  - Parameter cc: The email address to which the email will be sent.
    public init(text: String? = nil, html: String? = nil, attachments: [MessageAttachmentOptions]? = nil, cc: String? = nil) {
        self.cc = cc
        self.text = text
        self.html = html
        self.attachments = attachments
    }
}
