//
//  PreviewsModels.swift
//  Mailosaur
//
//  Created by Mailosaur on 20.01.2023.
//

public struct Preview: Decodable {
    /// The unique identifier for the email preview.
    public let id: String
    /// The email client the preview was generated with.
    public let emailClient: String
    /// Whether images were disabled in the preview.
// TODO This is a bug - should never be undefined
//    public let disableImages: Bool
}

public struct PreviewListResult: Decodable {
    /// A list of requested email previews.
    public let items: [Preview]
}

public struct PreviewRequestOptions: Encodable {
    /// The list of email clients to generate previews with.
    public let emailClients: [String]
    
    ///  Initializes a new instance of the PreviewRequestOptions class.
    ///  - Parameter emailClients: The list of email clients to generate previews with.
    public init(emailClients: [String]) {
        self.emailClients = emailClients
    }
}

public struct EmailClient: Decodable {
    /// The unique email client label. Used when generating email preview requests.
    public let label: String
    /// The display name of the email client.
    public let name: String
}

public struct EmailClientListResult: Decodable {
    /// A list of available email clients with which to generate email previews.
    public let items: [EmailClient]
}
