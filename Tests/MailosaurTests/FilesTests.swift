//
//  FilesTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 28.01.2023.
//

import XCTest
@testable import Mailosaur

class FilesTestsSetup {
    static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    static let server = ProcessInfo.processInfo.environment["MAILOSAUR_SERVER"]!
    static var client: MailosaurClient!
    static var email: Message!
    static var initialized = false
    
    static func beforeAll() async throws {
        guard initialized == false else { return }
        self.initialized = true
        
        let client = MailosaurClient(config: MailosaurConfig(apiKey: self.apiKey, baseUrl: URL(string: self.apiBaseUrl)!))
        self.client = client
        
        let host = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_HOST"]  ?? "mailosaur.net"
        let testEmailAddress = "files_test@\(self.server).\(host)"

        try await Mailer.shared.sendEmail(client: client, server: self.server, sendToAddress: testEmailAddress)
    
        let email = try await self.client.messages.get(server: self.server, criteria: MessageSearchCriteria(sentTo: testEmailAddress))
        self.email = email
    }
}

final class FilesTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        try await FilesTestsSetup.beforeAll()
    }
    
    func testGetEmail() async throws {
        let bytes = try await FilesTestsSetup.client.files.getEmail(id: FilesTestsSetup.email.id)
        let rawEmail = String(data: bytes, encoding: .utf8)
        
        XCTAssertNotNil(rawEmail)
        guard let rawEmail = rawEmail else { return }
        XCTAssertTrue(rawEmail.count > 0)
        XCTAssertTrue(rawEmail.contains(FilesTestsSetup.email.subject.data(using: .utf8)!.base64EncodedString()))
    }
    
    func testGetAttachment() async throws {
        let attachment = FilesTestsSetup.email.attachments[0]
        let bytes = try await FilesTestsSetup.client.files.getAttachment(id: attachment.id)
        
        XCTAssertEqual(attachment.length ?? -1, bytes.count)
    }
}
