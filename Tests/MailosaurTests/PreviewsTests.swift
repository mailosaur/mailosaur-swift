//
//  PreviewsTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 28.01.2023.
//

import Foundation
import Testing
@testable import Mailosaur

actor PreviewsTestsSetup {
    static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    static let server = ProcessInfo.processInfo.environment["MAILOSAUR_SERVER"]!
    static let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
}

@Suite("Email Preview Tests", .serialized)
struct PreviewsTests {
    
    @Test("List available email clients")
    func listEmailClients() async throws {
        let result = try await PreviewsTestsSetup.client.previews.listEmailClients();
        #expect(result.items.count > 1)
    }
    
    @Test("Generate email previews")
    func generatePreviews() async throws {
        let randomString = Mailer.shared.getRandomString(length: 10)
        let host = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_HOST"]  ?? "mailosaur.net"
        let testEmailAddress = "\(randomString)@\(PreviewsTestsSetup.server).\(host)"

        try await Mailer.shared.sendEmail(client: PreviewsTestsSetup.client, server: PreviewsTestsSetup.server, sendToAddress: testEmailAddress)

        let email = try await PreviewsTestsSetup.client.messages.get(server: PreviewsTestsSetup.server, criteria: MessageSearchCriteria(sentTo: testEmailAddress))
        
        let options = PreviewRequestOptions(emailClients: ["iphone-16plus-applemail-lightmode-portrait"])
        
        let result = try await PreviewsTestsSetup.client.messages.generatePreviews(id: email.id, options: options)
        #expect(result.items.count > 0)
                    
        let bytes = try await PreviewsTestsSetup.client.files.getPreview(id: result.items[0].id)
        #expect(bytes.count > 1)
    }
}
