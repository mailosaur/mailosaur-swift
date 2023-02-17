//
//  ErrorsTests.swift
//  mailosaur-swiftTests
//
//  Created by Mailosaur on 26.01.2023.
//

import XCTest
@testable import mailosaur_swift

final class ErrorsTests: XCTestCase {
    private static var client: MailosaurClient!
    private static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    private static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    
    override class func setUp() {
        super.setUp()
        
        let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
        self.client = client
    }
    
    func testUnauthorized() async throws {
        let unauthorizedClient = MailosaurClient(config: MailosaurConfig(apiKey: "wrongKey"))
        do {
            _ = try await unauthorizedClient.servers.list()
        } catch (let error) {
            if case let MailosaurError.serverError(message) = error {
                XCTAssertTrue(message.contains("Authentication failed"))
                return
            } else {
                XCTFail("Error is not a MailosaurError")
            }
        }
        
        XCTFail("Test should end with an error, but it didn't")
    }
    
    func testNotFound() async throws {
        do {
            _ = try await Self.client.servers.get(id: "not_found")
        } catch (let error) {
            if case let MailosaurError.serverError(message) = error {
                XCTAssertTrue(message.contains("Not found"))
                return
            } else {
                XCTFail("Error is not a MailosaurError")
            }
        }
        
        XCTFail("Test should end with an error, but it didn't")
    }

    func testBadRequest() async throws {
        let options = ServerCreateOptions(name: "")
        do {
            _ = try await Self.client.servers.create(options: options)
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
