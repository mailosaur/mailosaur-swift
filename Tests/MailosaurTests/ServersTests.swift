//
//  ServersTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 26.01.2023.
//

import XCTest
@testable import Mailosaur

final class ServersTests: XCTestCase {
    private static var client: MailosaurClient!
    private static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    private static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    
    override class func setUp() {
        super.setUp()
        
        let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
        self.client = client
    }
    
    func testList() async throws {
        let servers = try await Self.client.servers.list().items
        XCTAssertTrue(servers.count > 1)
    }
    
    func testGetNotfound() async throws {
        do {
            _ = try await Self.client.servers.get(id: "efe907e9-74ed-4113-a3e0-a3d41d914765")
        } catch (let error) {
            if case let MailosaurError.serverError(message) = error {
                XCTAssertTrue(message.contains("Not found"))
                return
            } else {
                XCTFail("Error is not a MailosaurError")
            }
        }
    }
    
    func testCrud() async throws {
        let serverName = "My test"
        let options = ServerCreateOptions(name: serverName)
        
        // Create a new server
        let createdServer = try await Self.client.servers.create(options: options)
        XCTAssertFalse(createdServer.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertEqual(createdServer.name, serverName)
//        XCTAssertNotNil(createdServer.users)
        XCTAssertEqual(0, createdServer.messages)
        
        // Retrieve a server and confirm it has expected content
        let retrievedServer = try await Self.client.servers.get(id: createdServer.id)
        XCTAssertEqual(createdServer.id, retrievedServer.id)
        XCTAssertEqual(createdServer.name, retrievedServer.name)
        XCTAssertEqual(createdServer.users, retrievedServer.users)
        XCTAssertEqual(createdServer.messages, retrievedServer.messages)
        
        // Update a server and confirm it has changed
        let updatedServerParams = Server(id: retrievedServer.id,
                                         name: "\(retrievedServer.name) updated with ellipsis … and emoji 👨🏿‍🚒",
                                         users: retrievedServer.users,
                                         messages: retrievedServer.messages)
        let updatedServer = try await Self.client.servers.update(id: updatedServerParams.id, server: updatedServerParams)
        XCTAssertEqual(updatedServerParams.id, updatedServer.id)
        XCTAssertEqual(updatedServerParams.name, updatedServer.name)
        XCTAssertEqual(updatedServerParams.users, updatedServer.users)
        XCTAssertEqual(updatedServerParams.messages, updatedServer.messages)
        
        // Delete server
        try await Self.client.servers.delete(id: retrievedServer.id)
        
        // Attempting to delete again should fail
        do {
            try await Self.client.servers.delete(id: retrievedServer.id)
        } catch (let error) {
            XCTAssertTrue(error is MailosaurError)
            return
        }
        
        XCTFail("Test should end with an error, but it didn't")
    }
    
    func testFailedCreate() async throws {
        guard let client = Self.client else {
            XCTFail("Client is not initialized")
            return
        }
        
        let options = ServerCreateOptions(name: "")
        do {
            _ = try await client.servers.create(options: options)
        } catch (let error) {
            if case let MailosaurError.serverError(message) = error {
                XCTAssertTrue(message.contains("Servers need a name"))
                return
            } else {
                XCTFail("Error is not a MailosaurError")
            }
        }
        
        XCTFail("Test should end with an error, but it didn't")
    }
}
