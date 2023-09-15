//
//  PreviewsTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 28.01.2023.
//

import XCTest
@testable import Mailosaur

class PreviewsTestsSetup {
    static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    static let server = ProcessInfo.processInfo.environment["MAILOSAUR_PREVIEWS_SERVER"]!
    static var client: MailosaurClient!
    static var initialized = false
    
    static func beforeAll() async throws {
        guard initialized == false else { return }
        self.initialized = true
        
        let client = MailosaurClient(config: MailosaurConfig(apiKey: self.apiKey, baseUrl: URL(string: self.apiBaseUrl)!))
        self.client = client
    }
}

final class PreviewsTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        try await PreviewsTestsSetup.beforeAll()
    }
    
    func testListEmailClients() async throws {
        let result = try await PreviewsTestsSetup.client.previews.listEmailClients();
        XCTAssertTrue(result.items.count > 1)
    }
    
    func testGeneratePreviews() async throws {
        try XCTSkipIf(EmailsTestsSetup.server == nil, "Skipping test")
        
        let randomString = Mailer.shared.getRandomString(length: 10)
        let host = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_HOST"]  ?? "mailosaur.net"
        let testEmailAddress = "\(randomString)@\(PreviewsTestsSetup.server).\(host)"

        try await Mailer.shared.sendEmail(client: PreviewsTestsSetup.client, server: PreviewsTestsSetup.server, sendToAddress: testEmailAddress)

        let email = try await PreviewsTestsSetup.client.messages.get(server: PreviewsTestsSetup.server, criteria: MessageSearchCriteria(sentTo: testEmailAddress))
        
        let request = PreviewRequest(emailClient: "OL2021")
        let options = PreviewRequestOptions(previews: [request])
        
        let result = try await PreviewsTestsSetup.client.messages.generatePreviews(id: email.id, options: options)
        XCTAssertTrue(result.items.count > 0)
                    
        let bytes = try await PreviewsTestsSetup.client.files.getPreview(id: result.items[0].id)
        XCTAssertTrue(bytes.count > 1)
    }
}
