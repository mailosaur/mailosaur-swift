//
//  UsageTests.swift
//  mailosaur-swiftTests
//
//  Created by Mailosaur on 26.01.2023.
//

import XCTest
@testable import mailosaur_swift

final class UsageTests: XCTestCase {
    private static var client: MailosaurClient!
    private static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    private static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    
    override class func setUp() {
        super.setUp()
        
        let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
        self.client = client
    }
    
    func testLimits() async throws {
        let result = try await Self.client.usage.limits()
        XCTAssertNotNil(result.servers)
        XCTAssertNotNil(result.users)
        XCTAssertNotNil(result.email)
        XCTAssertNotNil(result.sms)
        
        XCTAssertTrue(result.servers.limit > 0)
        XCTAssertTrue(result.users.limit > 0)
        XCTAssertTrue(result.email.limit > 0)
        XCTAssertTrue(result.sms.limit > 0)
    }

    func testTransactions() async throws {
        guard let client = Self.client else {
            XCTFail("Client is not initialized")
            return
        }
        
        let result = try await client.usage.transactions()
        XCTAssertTrue(result.items.count > 1)
    }
}
