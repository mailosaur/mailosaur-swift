//
//  EmailsTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 28.01.2023.
//

import XCTest
@testable import Mailosaur

class EmailsTestsSetup {
    static var client: MailosaurClient!
    static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    static let server = ProcessInfo.processInfo.environment["MAILOSAUR_SERVER"]!
    static var emails: [MessageSummary]!
    static let verifiedDomain =  ProcessInfo.processInfo.environment["MAILOSAUR_VERIFIED_DOMAIN"]
    private static var initialized = false
    
    static func beforeAll() async throws {
        guard initialized == false else { return }
        self.initialized = true
        
        let client = MailosaurClient(config: MailosaurConfig(apiKey: self.apiKey, baseUrl: URL(string: self.apiBaseUrl)!))
        self.client = client
        
        try await client.messages.deleteAll(server: self.server)
        try await Mailer.shared.sendEmails(client: self.client, server: self.server, quantity: 5)
        self.emails = try await client.messages.list(server: self.server).items
    }
}

final class EmailsTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        try await EmailsTestsSetup.beforeAll()
    }
    
    func testEmail() throws {
        for email in EmailsTestsSetup.emails {
            validateEmailSummary(email: email)
        }
    }
    
    func testListReceivedAfter() async throws {
        let pastDate = Calendar.current.date(byAdding: .minute, value: -10, to: Date.now)
        let pastEmails = try await EmailsTestsSetup.client.messages.list(server: EmailsTestsSetup.server, receivedAfter: pastDate)
        
        XCTAssertGreaterThan(pastEmails.items.count, 0)
        
        let futureEmails = try await EmailsTestsSetup.client.messages.list(server: EmailsTestsSetup.server, receivedAfter: Date.now)
        
        XCTAssertEqual(0, futureEmails.items.count)
    }
    
    func testGet() async throws {
        let host = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_HOST"] ?? "mailosaur.net"
        let testEmailAddress = "wait_for_test@\(EmailsTestsSetup.server).\(host)"
        
        try await Mailer.shared.sendEmail(client: EmailsTestsSetup.client, server: EmailsTestsSetup.server, sendToAddress: testEmailAddress)
        
        let email = try await EmailsTestsSetup.client.messages.get(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria(sentTo: testEmailAddress))
        validateEmail(email: email)
    }
    
    func testGetById() async throws {
        let emailToRetrieve = EmailsTestsSetup.emails[0]
        let email = try await EmailsTestsSetup.client.messages.getById(id: emailToRetrieve.id)
        validateEmail(email: email)
        validateHeaders(email: email)
    }
    
    func testGetByIdNotFound() async throws {
        do {
            _ = try await EmailsTestsSetup.client.messages.getById(id: "efe907e9-74ed-4113-a3e0-a3d41d914765")
        } catch {
            return
        }
        
        XCTFail("Test should end with an error, but it didn't")
    }
    
    func testSearchNoCriteriaError() async throws {
        do {
            _ = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria())
        } catch {
            return
        }
        
        XCTFail("Test should end with an error, but it didn't")
    }
    
    func testSearchTimeoutErrorSuppressed() async throws {
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server,
                                                                       criteria: MessageSearchCriteria(sentFrom: "neverfound@example.com"),
                                                                       timeout: 1,
                                                                       errorOnTimeout: false).items
        XCTAssertEqual(0, result.count)
    }
    
    func testSearchBySentFrom() async throws {
        let targetEmail = EmailsTestsSetup.emails[1]
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria(sentFrom: targetEmail.from[0].email)).items
        
        XCTAssertEqual(1, result.count)
        XCTAssertEqual(targetEmail.to[0].email, result[0].to[0].email)
        XCTAssertEqual(targetEmail.subject, result[0].subject)
    }
    
    func testSearchByBody() async throws {
        let targetEmail = EmailsTestsSetup.emails[1]
        let uniqueString = targetEmail.subject.prefix(10)
        
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria(body: "\(uniqueString) html")).items
        
        XCTAssertEqual(1, result.count)
        XCTAssertEqual(targetEmail.to[0].email, result[0].to[0].email)
        XCTAssertEqual(targetEmail.subject, result[0].subject)
    }
    
    func testSearchBySubjectTest() async throws {
        let targetEmail = EmailsTestsSetup.emails[1]
        let uniqueString = String(targetEmail.subject.prefix(10))
        
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria(subject: uniqueString)).items
        
        XCTAssertEqual(1, result.count)
        XCTAssertEqual(targetEmail.to[0].email, result[0].to[0].email)
        XCTAssertEqual(targetEmail.subject, result[0].subject)
    }
    
    func testSearchWithMatchAll() async throws {
        let targetEmail = EmailsTestsSetup.emails[1]
        let uniqueString = String(targetEmail.subject.prefix(10))
        
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server,
                                                                       criteria: MessageSearchCriteria(subject: uniqueString,
                                                                                                       body: "this is a link",
                                                                                                       match: .all)).items
        
        XCTAssertEqual(1, result.count)
    }
    
    func testSearchWithMatchAny() async throws {
        let targetEmail = EmailsTestsSetup.emails[1]
        let uniqueString = String(targetEmail.subject.prefix(10))
        
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server,
                                                                       criteria: MessageSearchCriteria(subject: uniqueString,
                                                                                                       body: "this is a link",
                                                                                                       match: .any)).items
        
        XCTAssertEqual(5, result.count)
    }
    
    func testSearchWithSpecialCharacters() async throws {
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria(subject: "Search with ellipsis … and emoji 👨🏿‍🚒")).items
        XCTAssertEqual(0, result.count)
    }
    
    func testSpamAnalysis() async throws {
        let targetId = EmailsTestsSetup.emails[0].id
        let result = try await EmailsTestsSetup.client.analysis.spam(email: targetId)
        for rule in result.spamFilterResults.spamAssassin {
            XCTAssertTrue(rule.rule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            XCTAssertTrue(rule.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        }
    }
    
    func testDelete() async throws {
        let targetId = EmailsTestsSetup.emails[4].id
        
        try await EmailsTestsSetup.client.messages.delete(id: targetId)
        
        do {
            try await EmailsTestsSetup.client.messages.delete(id: targetId)
        } catch {
            return
        }
        
        XCTFail("Test should end with an error, but it didn't")
    }
    
    func testCreateSendText() async throws {
        try XCTSkipIf(EmailsTestsSetup.verifiedDomain == nil, "Skipping test")
        
        let subject = "New message"
        let message = try await EmailsTestsSetup.client.messages.create(server: EmailsTestsSetup.server, messageCreateOptions: MessageCreateOptions(to: "anything@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                                    send: true,
                                                                                                                                                    subject: subject,
                                                                                                                                                    text: "This is a new email"))
        
        XCTAssertFalse(message.id.isEmpty)
        XCTAssertEqual(subject, message.subject)
    }
    
    func testCreateSendHtml() async throws {
        try XCTSkipIf(EmailsTestsSetup.verifiedDomain == nil, "Skipping test")

        let subject = "New HTML message"
        let message = try await EmailsTestsSetup.client.messages.create(server: EmailsTestsSetup.server, messageCreateOptions: MessageCreateOptions(to: "anything@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                                    send: true,
                                                                                                                                                    subject: subject,
                                                                                                                                                    html: "<p>This is a new email.</p>"))
        
        XCTAssertFalse(message.id.isEmpty)
        XCTAssertEqual(subject, message.subject)
    }
    
    func testCreateSendWithAttachment() async throws {
        try XCTSkipIf(EmailsTestsSetup.verifiedDomain == nil, "Skipping test")
        
        let subject = "New message with attachment"
        let data = try Data(contentsOf: Bundle.module.url(forResource: "cat", withExtension: "png")!)
        let attachment = MessageAttachmentOptions(contentType: "image/png",
                                                  fileName: "cat.png",
                                                  content: data.base64EncodedString())
        
        let message = try await EmailsTestsSetup.client.messages.create(server: EmailsTestsSetup.server, messageCreateOptions: MessageCreateOptions(to: "anything@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                                    send: true,
                                                                                                                                                    subject: subject,
                                                                                                                                                    html: "<p>This is a new email.</p>",
                                                                                                                                                    attachments: [attachment]))
        
        XCTAssertEqual(1, message.attachments.count)
        let file1 = message.attachments[0]
        XCTAssertNotNil(file1.id)
        XCTAssertEqual(82138, file1.length)
        XCTAssertNotNil(file1.url)
        XCTAssertEqual("cat.png", file1.fileName)
        XCTAssertEqual("image/png", file1.contentType)
    }
    
    func testForwardText() async throws {
        try XCTSkipIf(EmailsTestsSetup.verifiedDomain == nil, "Skipping test")
        
        let body = "Forwarded message"
        let targetEmail = EmailsTestsSetup.emails[0]
        
        let message = try await EmailsTestsSetup.client.messages.forward(id: targetEmail.id, messageForwardOptions: MessageForwardOptions(to: "anything@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                          text: body))
        
        XCTAssertFalse(message.id.isEmpty)
        XCTAssertTrue(message.text.body?.contains(body) == true)
    }
    
    func testForwardHtml() async throws {
        try XCTSkipIf(EmailsTestsSetup.verifiedDomain == nil, "Skipping test")
        
        let body = "<p>Forwarded <strong>HTML</strong> message.</p>"
        let targetEmail = EmailsTestsSetup.emails[0]
        
        let message = try await EmailsTestsSetup.client.messages.forward(id: targetEmail.id, messageForwardOptions: MessageForwardOptions(to: "anything@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                          html: body))
        
        XCTAssertFalse(message.id.isEmpty)
        XCTAssertTrue(message.html.body?.contains(body) == true)
    }
    
    func testReplyText() async throws {
        try XCTSkipIf(EmailsTestsSetup.verifiedDomain == nil, "Skipping test")
        
        let body = "Reply message"
        let targetEmail = EmailsTestsSetup.emails[0]
        
        let message = try await EmailsTestsSetup.client.messages.reply(id: targetEmail.id, messageReplyOptions: MessageReplyOptions(text: body))
        
        XCTAssertFalse(message.id.isEmpty)
        XCTAssertTrue(message.text.body!.contains(body))
    }
    
    func testReplyHtml() async throws {
        try XCTSkipIf(EmailsTestsSetup.verifiedDomain == nil, "Skipping test")
        
        let body = "<p>Reply <strong>HTML</strong> message.</p>"
        let targetEmail = EmailsTestsSetup.emails[0]
        
        let message = try await EmailsTestsSetup.client.messages.reply(id: targetEmail.id, messageReplyOptions: MessageReplyOptions(html: body))
        
        XCTAssertFalse(message.id.isEmpty)
        XCTAssertTrue(message.html.body?.contains(body) == true)
    }
    
    func testReplyWithAttachment() async throws {
        try XCTSkipIf(EmailsTestsSetup.verifiedDomain == nil, "Skipping test")
        
        let body = "<p>Reply with attachment.</p>"
        let targetEmail = EmailsTestsSetup.emails[0]
        
        let data = try Data(contentsOf: Bundle.module.url(forResource: "cat", withExtension: "png")!)
        let attachment = MessageAttachmentOptions(contentType: "image/png",
                                                  fileName: "cat.png",
                                                  content: data.base64EncodedString())
        
        let message = try await EmailsTestsSetup.client.messages.reply(id: targetEmail.id, messageReplyOptions: MessageReplyOptions(html: body,
                                                                                                                                    attachments: [attachment]))
        XCTAssertEqual(1, message.attachments.count)
        let file1 = message.attachments[0]
        XCTAssertNotNil(file1.id)
        XCTAssertEqual(82138, file1.length)
        XCTAssertNotNil(file1.url)
        XCTAssertEqual("cat.png", file1.fileName)
        XCTAssertEqual("image/png", file1.contentType)
    }
    
    private func validateEmailSummary(email: MessageSummary) {
        validateMetadata(email: email)
        XCTAssertTrue(email.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        XCTAssertEqual(2, email.attachments)
    }
    
    private func validateMetadata(email: Message) {
        validateMetadata(email: MessageSummary(id: email.id,
                                               type: email.type,
                                               from: email.from,
                                               to: email.to,
                                               cc: email.cc,
                                               bcc: email.bcc,
                                               received: email.received,
                                               subject: email.subject,
                                               summary: "",
                                               server: email.server,
                                               attachments: email.attachments.count))
    }
    
    private func validateMetadata(email: MessageSummary) {
        XCTAssertEqual("Email", email.type)
        XCTAssertEqual(1, email.from.count)
        XCTAssertEqual(1, email.to.count)
        XCTAssertTrue(email.from[0].email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        XCTAssertTrue(email.from[0].name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        XCTAssertTrue(email.to[0].email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        XCTAssertTrue(email.to[0].name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        XCTAssertTrue(email.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        XCTAssertLessThanOrEqual(Date.now.timeIntervalSince(email.received) / 3600, 1)
    }
    
    private func validateEmail(email: Message) {
        validateMetadata(email: email)
        validateAttachmentMetadata(email: email)
        validateHtml(email: email)
        validateText(email: email)
        
        XCTAssertNotNil(email.metadata.ehlo)
        XCTAssertNotNil(email.metadata.mailFrom)
        XCTAssertEqual(1, email.metadata.rcptTo.count)
    }
    
    private func validateAttachmentMetadata(email: Message) {
        XCTAssertEqual(2, email.attachments.count)
        
        let file1 = email.attachments[0]
        XCTAssertNotNil(file1.id)
        XCTAssertEqual(82138, file1.length)
        XCTAssertNotNil(file1.url)
        XCTAssertEqual("cat.png", file1.fileName)
        XCTAssertEqual("image/png", file1.contentType)
        
        let file2 = email.attachments[1]
        XCTAssertNotNil(file2.id)
        XCTAssertEqual(212080, file2.length)
        XCTAssertNotNil(file2.url)
        XCTAssertEqual("dog.png", file2.fileName)
        XCTAssertEqual("image/png", file2.contentType)
    }
    
    private func validateHtml(email: Message) {
        XCTAssertTrue(email.html.body?.starts(with: "<div dir=\"ltr\">") == true)
        
        XCTAssertEqual(3, email.html.links.count)
        XCTAssertEqual("https://mailosaur.com/", email.html.links[0].href)
        XCTAssertEqual("mailosaur", email.html.links[0].text)
        XCTAssertEqual("https://mailosaur.com/", email.html.links[1].href)
        XCTAssertNil(email.html.links[1].text)
        XCTAssertEqual("http://invalid/", email.html.links[2].href)
        XCTAssertEqual("invalid", email.html.links[2].text)
        
        XCTAssertEqual(2, email.html.codes.count)
        XCTAssertEqual("123456", email.html.codes[0].value)
        XCTAssertEqual("G3H1Y2", email.html.codes[1].value)
        
        XCTAssertTrue(email.html.images?[1].src.starts(with: "cid:") ?? false)
        XCTAssertEqual("Inline image 1", email.html.images?[1].alt)
    }
    
    private func validateText(email: Message) {
        XCTAssertTrue(email.text.body?.starts(with: "this is a test") == true)
        
        XCTAssertEqual(2, email.text.links.count)
        XCTAssertEqual(email.text.links[0].text, email.text.links[0].href)
        XCTAssertEqual("https://mailosaur.com/", email.text.links[0].text)
        XCTAssertEqual(email.text.links[1].text, email.text.links[1].href)
        XCTAssertEqual("https://mailosaur.com/", email.text.links[1].text)
        
        XCTAssertEqual(2, email.text.codes.count)
        XCTAssertEqual("654321", email.text.codes[0].value)
        XCTAssertEqual("5H0Y2", email.text.codes[1].value)
    }
    
    private func validateHeaders(email: Message) {
        
    }
}
