//
//  UsageTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 26.01.2023.
//

import Foundation
import Testing
@testable import Mailosaur

@Suite("Usage API Tests")
struct UsageTests {
    private static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    private static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    private static let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
    
    @Test("Retrieve usage limits")
    func limits() async throws {
        let result = try await Self.client.usage.limits()
        #expect(result.servers != nil)
        #expect(result.users != nil)
        #expect(result.email != nil)
        #expect(result.sms != nil)
        
        #expect(result.servers.limit > 0)
        #expect(result.users.limit > 0)
        #expect(result.email.limit > 0)
        #expect(result.sms.limit > 0)
    }

    @Test("Retrieve usage transactions")
    func transactions() async throws {
        let result = try await Self.client.usage.transactions()
        #expect(result.items.count > 1)
    }
}
