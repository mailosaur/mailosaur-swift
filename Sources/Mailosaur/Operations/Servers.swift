//
//  Servers.swift
//  Mailosaur
//
//  Created by Mailosaur on 20.01.2023.
//

import Foundation

/// Operations for creating and managing your Mailosaur inboxes (servers) — they
/// group your tests together, each with its own domain and SMTP/POP3/IMAP credentials.
/// Accessed via `client.servers`.
public class Servers {
    // Must be weak to prevent a retain cycle
    private weak var client: MailosaurClient?
    
    public init(client: MailosaurClient) {
        self.client = client
    }
    
    /// Returns a list of your inboxes (servers). Inboxes (servers) are returned sorted in alphabetical order.
    ///
    /// - Returns: A `Result` containing a ``ServerListResult`` of your inboxes (servers) on success, or an `Error` on failure.
    public func listResult() async -> Result<ServerListResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/servers")
    }
    
    /// Returns a list of your inboxes (servers). Inboxes (servers) are returned sorted in alphabetical order.
    ///
    /// - Returns: A ``ServerListResult`` containing your inboxes (servers).
    public func list() async throws -> ServerListResult {
        let result = await self.listResult()
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Creates a new inbox (server).
    ///
    ///  - Parameter options: Options used to create a new Mailosaur inbox (server).
    ///  - Returns: A `Result` containing the newly-created ``Server`` on success, or an `Error` on failure.
    public func createResult(options: ServerCreateOptions) async -> Result<Server, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/servers", method: .post, params: options)
    }
    
    /// Creates a new inbox (server).
    ///
    ///  - Parameter options: Options used to create a new Mailosaur inbox (server).
    ///  - Returns: The newly-created ``Server``.
    public func create(options: ServerCreateOptions) async throws -> Server {
        let result = await self.createResult(options: options)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Retrieves the detail for a single inbox (server).
    ///
    ///  - Parameter id: The unique identifier of the inbox (server).
    ///  - Returns: A `Result` containing the ``Server`` on success, or an `Error` on failure.
    public func getResult(id: String) async -> Result<Server, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/servers/\(id)")
    }
    
    /// Retrieves the detail for a single inbox (server).
    ///
    ///  - Parameter id: The unique identifier of the inbox (server).
    ///  - Returns: The ``Server``.
    public func get(id: String) async throws -> Server {
        let result = await self.getResult(id: id)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Updates the attributes of an inbox (server).
    ///
    ///  - Parameters:
    ///    - id: The unique identifier of the inbox (server).
    ///    - server: The updated inbox (server).
    ///  - Returns: A `Result` containing the updated ``Server`` on success, or an `Error` on failure.
    public func updateResult(id: String, server: Server) async -> Result<Server, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/servers/\(id)", method: .put, params: server)
    }
    
    /// Updates the attributes of an inbox (server).
    ///
    ///  - Parameters:
    ///    - id: The unique identifier of the inbox (server).
    ///    - server: The updated inbox (server).
    ///  - Returns: The updated ``Server``.
    public func update(id: String, server: Server) async throws -> Server {
        let result = await self.updateResult(id: id, server: server)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Permanently delete an inbox (server). This will also delete all messages, associated attachments, etc. within the inbox (server). This operation cannot be undone.
    ///
    ///  - Parameter id: The unique identifier of the inbox (server).
    ///  - Returns: A `Result` that is successful once the inbox (server) has been deleted, or an `Error` on failure.
    public func deleteResult(id: String) async -> Result<(), Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        let result: Result<MailosaurClient.None, Error> = await client.performRequest(path: "api/servers/\(id)", method: .delete)
        return result.map { _ in () }
    }
    
    /// Permanently delete an inbox (server). This will also delete all messages, associated attachments, etc. within the inbox (server). This operation cannot be undone.
    ///
    ///  - Parameter id: The unique identifier of the inbox (server).
    ///  - Returns: Once the inbox (server) has been deleted.
    public func delete(id: String) async throws {
        let result = await self.deleteResult(id: id)
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    /// Generates a random email address by appending a random string in front of the domain name of the inbox (server).
    ///
    ///  - Parameter serverId: The identifier of the inbox (server).
    ///  - Returns: A random email address ending in the domain of the inbox (server).
    public static func generateEmailAddress(serverId: String) -> String {
        let host = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_HOST"] ?? "mailosaur.net"
        let uuid = UUID().uuidString.lowercased()
        return "\(uuid)@\(serverId).\(host)"
    }
}
