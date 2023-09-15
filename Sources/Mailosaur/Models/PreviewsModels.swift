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

public struct PreviewRequest: Encodable {
    /// The email client you wish to generate a preview for.
    public let emailClient: String
    /// Gets or sets whether images will be disabled (only if supported by the client).
    public let disableImages: Bool
    
    ///  Initializes a new instance of the PreviewRequest class.
    ///  - Parameter emailClient: The email client you wish to generate a preview for.
    ///  - Parameter disableImages: Whether images will be disabled (only if supported by the client).
    public init(emailClient: String, disableImages: Bool = false) {
        self.emailClient = emailClient
        self.disableImages = disableImages
    }
}

public struct PreviewRequestOptions: Encodable {
    /// Sets the list of email preview requests.
    public let previews: [PreviewRequest]
}

public struct PreviewEmailClient: Decodable {
    /// The unique identifier for the email preview.
    public let id: String
    /// The display name of the email client.
    public let name: String
    /// Whether the platform is desktop, mobile, or web-based.
    public let platformGroup: String
    /// The type of platform on which the email client is running.
    public let platformType: String
    /// The platform version number.
    public let platformVersion: String
    /// Whether images can be disabled when generating previews.
    public let canDisableImages: Bool
    /// The current status of the email client.
    public let status: String
}

public struct PreviewEmailClientListResult: Decodable {
    /// A list of available email clients with which to generate email previews.
    public let items: [PreviewEmailClient]
}
