//
//  ServersModels.swift
//  Mailosaur
//
//  Created by Mailosaur on 20.01.2023.
//

public struct Server: Codable {
    /// Gets or sets unique identifier for the server. Used as username for
    /// SMTP/POP3 authentication.
    public let id: String
    /// Gets or sets a name used to identify the server.
    public let name: String
    /// Gets or sets users (excluding administrators) who have access to
    /// the server.
    public let users: [String]
    /// Gets or sets the number of messages currently in the server.
    public let messages: Int
}

public struct ServerListResult: Decodable {
    /// Gets or sets the individual servers forming the result. Servers are
    /// returned sorted by creation date, with the most recently-created
    /// server appearing first.
    public let items: [Server]
}

public struct ServerCreateOptions: Encodable {
    /// Gets or sets a name used to identify the server.
    public let name: String
}
