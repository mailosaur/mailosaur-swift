//
//  Servers.swift
//  mailosaur-swift
//
//  Created by Mailosaur on 20.01.2023.
//

import Foundation

public class Servers {
    // Must be weak to prevent a retain cycle
    private weak var client: MailosaurClient?
    
    public init(client: MailosaurClient) {
        self.client = client
    }
    
    /// Returns a list of your virtual servers. Servers are returned sorted in alphabetical order.
    public func listResult() async -> Result<ServerListResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/servers")
    }
    
    /// Returns a list of your virtual servers. Servers are returned sorted in alphabetical order.
    public func list() async throws -> ServerListResult {
        let result = await self.listResult()
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Creates a new virtual server.
    ///
    ///  - Parameter options: Options used to create a new Mailosaur server.
    public func createResult(options: ServerCreateOptions) async -> Result<Server, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/servers", method: .post, params: options)
    }
    
    /// Creates a new virtual server.
    ///
    ///  - Parameter options: Options used to create a new Mailosaur server.
    public func create(options: ServerCreateOptions) async throws -> Server {
        let result = await self.createResult(options: options)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Retrieves the detail for a single server.
    ///
    ///  - Parameter id: The unique identifier of the server.
    public func getResult(id: String) async -> Result<Server, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/servers/\(id)")
    }
    
    /// Retrieves the detail for a single server.
    ///
    ///  - Parameter id: The unique identifier of the server.
    public func get(id: String) async throws -> Server {
        let result = await self.getResult(id: id)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Updates the attributes of a server.
    ///
    ///  - Parameter id: The unique identifier of the server.
    ///  - Parameter server: The updated server.
    public func updateResult(id: String, server: Server) async -> Result<Server, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/servers/\(id)", method: .put, params: server)
    }
    
    /// Updates the attributes of a server.
    ///
    ///  - Parameter id: The unique identifier of the server.
    ///  - Parameter server: The updated server.
    public func update(id: String, server: Server) async throws -> Server {
        let result = await self.updateResult(id: id, server: server)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Permanently delete a server. This will also delete all messages, associated attachments, etc. within the server. This operation cannot be undone.
    ///
    ///  - Parameter id: The unique identifier of the server.
    public func deleteResult(id: String) async -> Result<(), Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        let result: Result<MailosaurClient.None, Error> = await client.performRequest(path: "api/servers/\(id)", method: .delete)
        return result.map { _ in () }
    }
    
    /// Permanently delete a server. This will also delete all messages, associated attachments, etc. within the server. This operation cannot be undone.
    ///
    ///  - Parameter id: The unique identifier of the server.
    public func delete(id: String) async throws {
        let result = await self.deleteResult(id: id)
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    /// Generates a random email address by appending a random string in front of the server's domain name.
    ///
    ///  - Parameter serverId: The identifier of the server.
    public static func generateEmailAddress(serverId: String) -> String {
        let host = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_HOST"] ?? "mailosaur.net"
        let uuid = UUID().uuidString.lowercased()
        return "\(uuid)@\(serverId).\(host)"
    }
}
