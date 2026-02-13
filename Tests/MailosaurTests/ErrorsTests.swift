//
//  ErrorsTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 26.01.2023.
//

import Foundation
import Testing
@testable import Mailosaur

@Suite("Error Handling Tests")
struct ErrorsTests {
    private static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    private static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    private static let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
    
    @Test("Unauthorized access returns authentication error")
    func unauthorized() async throws {
        let unauthorizedClient = MailosaurClient(config: MailosaurConfig(apiKey: "wrongKey"))
        do {
            _ = try await unauthorizedClient.servers.list()
            Issue.record("Test should have thrown an error, but it didn't")
        } catch (let error) {
            if case let MailosaurError.serverError(message) = error {
                #expect(message.contains("Authentication failed"))
            } else {
                Issue.record("Error is not a MailosaurError")
            }
        }
    }
    
    @Test("Not found error for invalid server ID")
    func notFound() async throws {
        do {
            _ = try await Self.client.servers.get(id: "not_found")
            Issue.record("Test should have thrown an error, but it didn't")
        } catch (let error) {
            if case let MailosaurError.serverError(message) = error {
                #expect(message.contains("Not found"))
            } else {
                Issue.record("Error is not a MailosaurError")
            }
        }
    }

    @Test("Bad request error for invalid server name")
    func badRequest() async throws {
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
