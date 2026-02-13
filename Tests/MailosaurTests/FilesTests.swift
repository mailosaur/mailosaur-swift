//
//  FilesTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 28.01.2023.
//

import Foundation
import Testing
@testable import Mailosaur

actor FilesTestsSetup {
    static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    static let server = ProcessInfo.processInfo.environment["MAILOSAUR_SERVER"]!
    static let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
    private static var _email: Message?
    private static var initializationTask: Task<Message, Error>?
    
    static func ensureInitialized() async throws -> Message {
        if let email = _email {
            return email
        }
        
        if let task = initializationTask {
            return try await task.value
        }
        
        let task = Task<Message, Error> {
            let host = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_HOST"]  ?? "mailosaur.net"
            let testEmailAddress = "files_test@\(server).\(host)"

            try await Mailer.shared.sendEmail(client: client, server: server, sendToAddress: testEmailAddress)
        
            let email = try await client.messages.get(server: server, criteria: MessageSearchCriteria(sentTo: testEmailAddress))
            _email = email
            return email
        }
        
        initializationTask = task
        return try await task.value
    }
}

@Suite("File Operations Tests", .serialized)
struct FilesTests {
    
    @Test("Get email as raw MIME data")
    func getEmail() async throws {
        let email = try await FilesTestsSetup.ensureInitialized()
        let bytes = try await FilesTestsSetup.client.files.getEmail(id: email.id)
        let rawEmail = String(data: bytes, encoding: .utf8)
        
        #expect(rawEmail != nil)
        guard let rawEmail = rawEmail else { return }
        #expect(rawEmail.count > 0)
        #expect(rawEmail.contains(email.subject))
    }
    
    @Test("Get attachment")
    func getAttachment() async throws {
        let email = try await FilesTestsSetup.ensureInitialized()
        let attachment = email.attachments[0]
        let bytes = try await FilesTestsSetup.client.files.getAttachment(id: attachment.id)
        
        #expect(bytes.count == attachment.length ?? -1)
    }
}
