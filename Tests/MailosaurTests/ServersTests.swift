//
//  ServersTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 26.01.2023.
//

import Foundation
import Testing
@testable import Mailosaur

@Suite("Server Management Tests")
struct ServersTests {
    private static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    private static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    private static let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
    
    @Test("List servers")
    func list() async throws {
        let servers = try await Self.client.servers.list().items
        #expect(servers.count > 1)
    }
    
    @Test("Get non-existent server returns not found error")
    func getNotfound() async throws {
        do {
            _ = try await Self.client.servers.get(id: "efe907e9-74ed-4113-a3e0-a3d41d914765")
            Issue.record("Test should have thrown an error, but it didn't")
        } catch (let error) {
            if case let MailosaurError.serverError(message) = error {
                #expect(message.contains("Not found"))
            } else {
                Issue.record("Error is not a MailosaurError")
            }
        }
    }
    
    @Test("Create, retrieve, update, and delete server")
    func crud() async throws {
        let serverName = "My test"
        let options = ServerCreateOptions(name: serverName)
        
        // Create a new server
        let createdServer = try await Self.client.servers.create(options: options)
        #expect(!createdServer.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        #expect(createdServer.name == serverName)
//        #expect(createdServer.users != nil)
        #expect(createdServer.messages == 0)
        
        // Retrieve a server and confirm it has expected content
        let retrievedServer = try await Self.client.servers.get(id: createdServer.id)
        #expect(createdServer.id == retrievedServer.id)
        #expect(createdServer.name == retrievedServer.name)
        #expect(createdServer.users == retrievedServer.users)
        #expect(createdServer.messages == retrievedServer.messages)
        
        // Update a server and confirm it has changed
        let updatedServerParams = Server(id: retrievedServer.id,
                                         name: "\(retrievedServer.name) updated with ellipsis … and emoji 👨🏿‍🚒",
                                         users: retrievedServer.users,
                                         messages: retrievedServer.messages)
        let updatedServer = try await Self.client.servers.update(id: updatedServerParams.id, server: updatedServerParams)
        #expect(updatedServerParams.id == updatedServer.id)
        #expect(updatedServerParams.name == updatedServer.name)
        #expect(updatedServerParams.users == updatedServer.users)
        #expect(updatedServerParams.messages == updatedServer.messages)
        
        // Delete server
        try await Self.client.servers.delete(id: retrievedServer.id)
        
        // Attempting to delete again should fail
        do {
            try await Self.client.servers.delete(id: retrievedServer.id)
            Issue.record("Test should have thrown an error, but it didn't")
        } catch (let error) {
            #expect(error is MailosaurError)
        }
    }
    
    @Test("Create server with empty name fails")
    func failedCreate() async throws {
        let options = ServerCreateOptions(name: "")
        do {
            _ = try await Self.client.servers.create(options: options)
            Issue.record("Test should have thrown an error, but it didn't")
        } catch (let error) {
            if case let MailosaurError.serverError(message) = error {
                #expect(message.contains("Servers need a name"))
            } else {
                Issue.record("Error is not a MailosaurError")
            }
        }
    }
}
