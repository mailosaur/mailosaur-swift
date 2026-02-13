//
//  EmailsTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 28.01.2023.
//

import Foundation
import Testing
@testable import Mailosaur

actor EmailsTestsSetup {
    static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    static let server = ProcessInfo.processInfo.environment["MAILOSAUR_SERVER"]!
    static let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
    static let verifiedDomain =  ProcessInfo.processInfo.environment["MAILOSAUR_VERIFIED_DOMAIN"]
    private static var _emails: [MessageSummary]?
    private static var initializationTask: Task<[MessageSummary], Error>?
    
    static func ensureInitialized() async throws -> [MessageSummary] {
        if let emails = _emails {
            return emails
        }
        
        if let task = initializationTask {
            return try await task.value
        }
        
        let task = Task<[MessageSummary], Error> {
            try await client.messages.deleteAll(server: server)
            try await Mailer.shared.sendEmails(client: client, server: server, quantity: 5)
            let emails = try await client.messages.list(server: server).items
            _emails = emails
            return emails
        }
        
        initializationTask = task
        return try await task.value
    }
}

@Suite("Email Message Tests", .serialized)
struct EmailsTests {
    
    @Test("List all email summaries")
    func listEmails() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        for email in emails {
            validateEmailSummary(email: email)
        }
    }
    
    @Test("List emails received after a specific date")
    func listReceivedAfter() async throws {
        try await EmailsTestsSetup.ensureInitialized()
        
        let pastDate = Calendar.current.date(byAdding: .minute, value: -10, to: Date.now)
        let pastEmails = try await EmailsTestsSetup.client.messages.list(server: EmailsTestsSetup.server, receivedAfter: pastDate)
        
        #expect(pastEmails.items.count > 0)
        
        let futureEmails = try await EmailsTestsSetup.client.messages.list(server: EmailsTestsSetup.server, receivedAfter: Date.now)
        
        #expect(futureEmails.items.count == 0)
    }
    
    @Test("Get email by search criteria")
    func getEmail() async throws {
        try await EmailsTestsSetup.ensureInitialized()
        
        let host = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_HOST"] ?? "mailosaur.net"
        let testEmailAddress = "wait_for_test@\(EmailsTestsSetup.server).\(host)"
        
        try await Mailer.shared.sendEmail(client: EmailsTestsSetup.client, server: EmailsTestsSetup.server, sendToAddress: testEmailAddress)
        
        let email = try await EmailsTestsSetup.client.messages.get(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria(sentTo: testEmailAddress))
        validateEmail(email: email)
    }
    
    @Test("Get email by ID")
    func getById() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let emailToRetrieve = emails[0]
        let email = try await EmailsTestsSetup.client.messages.getById(id: emailToRetrieve.id)
        validateEmail(email: email)
        validateHeaders(email: email)
    }
    
    @Test("Get email by invalid ID throws error")
    func getByIdNotFound() async throws {
        try await EmailsTestsSetup.ensureInitialized()
        
        do {
            _ = try await EmailsTestsSetup.client.messages.getById(id: "efe907e9-74ed-4113-a3e0-a3d41d914765")
        } catch {
            return
        }
        
        Issue.record("Test should end with an error, but it didn't")
    }
    
    @Test("Search with no criteria throws error")
    func searchNoCriteriaError() async throws {
        try await EmailsTestsSetup.ensureInitialized()
        
        do {
            _ = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria())
        } catch {
            return
        }
        
        Issue.record("Test should end with an error, but it didn't")
    }
    
    @Test("Search timeout error suppressed returns empty results")
    func searchTimeoutErrorSuppressed() async throws {
        try await EmailsTestsSetup.ensureInitialized()
        
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server,
                                                                       criteria: MessageSearchCriteria(sentFrom: "neverfound@example.com"),
                                                                       timeout: 1,
                                                                       errorOnTimeout: false).items
        #expect(result.count == 0)
    }
    
    @Test("Search emails by sent from address")
    func searchBySentFrom() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let targetEmail = emails[1]
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria(sentFrom: targetEmail.from[0].email)).items
        
        #expect(result.count == 1)
        #expect(result[0].to[0].email == targetEmail.to[0].email)
        #expect(result[0].subject == targetEmail.subject)
    }
    
    @Test("Search emails by body content")
    func searchByBody() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let targetEmail = emails[1]
        let uniqueString = targetEmail.subject.prefix(10)
        
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria(body: "\(uniqueString) html")).items
        
        #expect(result.count == 1)
        #expect(result[0].to[0].email == targetEmail.to[0].email)
        #expect(result[0].subject == targetEmail.subject)
    }
    
    @Test("Search emails by subject")
    func searchBySubject() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let targetEmail = emails[1]
        let uniqueString = String(targetEmail.subject.prefix(10))
        
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria(subject: uniqueString)).items
        
        #expect(result.count == 1)
        #expect(result[0].to[0].email == targetEmail.to[0].email)
        #expect(result[0].subject == targetEmail.subject)
    }
    
    @Test("Search with match all criteria")
    func searchWithMatchAll() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let targetEmail = emails[1]
        let uniqueString = String(targetEmail.subject.prefix(10))
        
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server,
                                                                       criteria: MessageSearchCriteria(subject: uniqueString,
                                                                                                       body: "this is a link",
                                                                                                       match: .all)).items
        
        #expect(result.count == 1)
    }
    
    @Test("Search with match any criteria")
    func searchWithMatchAny() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let targetEmail = emails[1]
        let uniqueString = String(targetEmail.subject.prefix(10))
        
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server,
                                                                       criteria: MessageSearchCriteria(subject: uniqueString,
                                                                                                       body: "this is a link",
                                                                                                       match: .any)).items
        
        #expect(result.count >= 5)
    }
    
    @Test("Search with special characters in subject")
    func searchWithSpecialCharacters() async throws {
        try await EmailsTestsSetup.ensureInitialized()
        
        let result = try await EmailsTestsSetup.client.messages.search(server: EmailsTestsSetup.server, criteria: MessageSearchCriteria(subject: "Search with ellipsis … and emoji 👨🏿‍🚒")).items
        #expect(result.count == 0)
    }
    
    @Test("Run spam analysis on email")
    func spamAnalysis() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let targetId = emails[0].id
        let result = try await EmailsTestsSetup.client.analysis.spam(email: targetId)
        for rule in result.spamFilterResults.spamAssassin {
            #expect(rule.rule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            #expect(rule.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        }
    }
    
    @Test("Generate deliverability report for email")
    func deliverabilityReport() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let targetId = emails[0].id
        let result = try await EmailsTestsSetup.client.analysis.deliverability(email: targetId)
        
        #expect(result != nil)
        
        #expect(result.spf != nil)
        #expect(result.spf?.result != nil)
        #expect(result.spf?.tags != nil)
        
        #expect(result.dkim != nil)
        for dkim in result.dkim {
            #expect(dkim != nil)
            #expect(dkim.result != nil)
            #expect(dkim.tags != nil)
        }
        
        #expect(result.dmarc != nil)
        #expect(result.dmarc?.rawValue != nil)
        #expect(result.dmarc?.tags != nil)
        
        #expect(result.blockLists != nil)
        for blockList in result.blockLists {
            #expect(blockList.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            #expect(blockList.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            #expect(blockList.result != nil)
        }
        
        #expect(result.content != nil)
        #expect(result.content.embed != nil)
        #expect(result.content.iframe != nil)
        #expect(result.content.object != nil)
        #expect(result.content.script != nil)
        #expect(result.content.shortUrls != nil)
        #expect(result.content.textSize != nil)
        #expect(result.content.totalSize != nil)
        #expect(result.content.missingAlt != nil)
        #expect(result.content.missingListUnsubscribe != nil)

        #expect(result.dnsRecords != nil)
        #expect(result.dnsRecords.a != nil)
        #expect(result.dnsRecords.mx != nil)
        #expect(result.dnsRecords.ptr != nil)
        
        #expect(result.spamAssassin != nil)
        for rule in result.spamAssassin.rules {
            #expect(rule.rule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            #expect(rule.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        }
    }
    
    @Test("Delete email by ID")
    func deleteEmail() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let targetId = emails[4].id
        
        try await EmailsTestsSetup.client.messages.delete(id: targetId)
        
        do {
            try await EmailsTestsSetup.client.messages.delete(id: targetId)
        } catch {
            return
        }
        
        Issue.record("Test should end with an error, but it didn't")
    }
    
    @Test("Create and send text email", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func createSendText() async throws {
        _ = try await EmailsTestsSetup.ensureInitialized()
        
        let subject = "New message"
        let message = try await EmailsTestsSetup.client.messages.create(server: EmailsTestsSetup.server, messageCreateOptions: MessageCreateOptions(to: "anything@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                                    send: true,
                                                                                                                                                    subject: subject,
                                                                                                                                                    text: "This is a new email"))
        
        #expect(!message.id.isEmpty)
        #expect(message.subject == subject)
    }
    
    @Test("Create and send HTML email", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func createSendHtml() async throws {
        _ = try await EmailsTestsSetup.ensureInitialized()

        let subject = "New HTML message"
        let message = try await EmailsTestsSetup.client.messages.create(server: EmailsTestsSetup.server, messageCreateOptions: MessageCreateOptions(to: "anything@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                                    send: true,
                                                                                                                                                    subject: subject,
                                                                                                                                                    html: "<p>This is a new email.</p>"))
        
        #expect(!message.id.isEmpty)
        #expect(message.subject == subject)
    }
    
    @Test("Create email with CC recipient", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func createWithCc() async throws {
        _ = try await EmailsTestsSetup.ensureInitialized()

        let subject = "CC message"
        let ccRecipient = "someoneelse@\(EmailsTestsSetup.verifiedDomain ?? "")"
        let message = try await EmailsTestsSetup.client.messages.create(server: EmailsTestsSetup.server, messageCreateOptions: MessageCreateOptions(to: "anything@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                                    send: true,
                                                                                                                                                    subject: subject,
                                                                                                                                                    html: "<p>This is a new email.</p>",
                                                                                                                                                    cc: ccRecipient))
        
        #expect(!message.id.isEmpty)
        #expect(message.subject == subject)
        #expect(message.cc.count == 1)
        #expect(message.cc[0].email == ccRecipient)
    }
    
    @Test("Create and send email with attachment", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func createSendWithAttachment() async throws {
        _ = try await EmailsTestsSetup.ensureInitialized()
        
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
        
        #expect(message.attachments.count == 1)
        let file1 = message.attachments[0]
        #expect(file1.id != nil)
        #expect(file1.length == 82138)
        #expect(file1.url != nil)
        #expect(file1.fileName == "cat.png")
        #expect(file1.contentType == "image/png")
    }
    
    @Test("Forward email as text", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func forwardText() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let body = "Forwarded message"
        let targetEmail = emails[0]
        
        let message = try await EmailsTestsSetup.client.messages.forward(id: targetEmail.id, messageForwardOptions: MessageForwardOptions(to: "anything@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                          text: body))
        
        #expect(!message.id.isEmpty)
        #expect(message.text.body?.contains(body) == true)
    }
    
    @Test("Forward email as HTML", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func forwardHtml() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let body = "<p>Forwarded <strong>HTML</strong> message.</p>"
        let targetEmail = emails[0]
        
        let message = try await EmailsTestsSetup.client.messages.forward(id: targetEmail.id, messageForwardOptions: MessageForwardOptions(to: "anything@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                          html: body))
        
        #expect(!message.id.isEmpty)
        #expect(message.html.body?.contains(body) == true)
    }
    
    @Test("Forward email with CC recipient", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func forwardWithCc() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()

        let body = "<p>Forwarded <strong>HTML</strong> message.</p>"
        let targetEmail = emails[0]
        let ccRecipient = "someoneelse@\(EmailsTestsSetup.verifiedDomain ?? "")"
        
        let message = try await EmailsTestsSetup.client.messages.forward(id: targetEmail.id, messageForwardOptions: MessageForwardOptions(to: "forwardcc@\(EmailsTestsSetup.verifiedDomain ?? "")",
                                                                                                                                          html: body,
                                                                                                                                          cc: ccRecipient))
        
        #expect(!message.id.isEmpty)
        #expect(message.html.body?.contains(body) == true)
        #expect(message.cc.count == 1)
        #expect(message.cc[0].email == ccRecipient)
    }
    
    @Test("Reply to email as text", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func replyText() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let body = "Reply message"
        let targetEmail = emails[0]
        
        let message = try await EmailsTestsSetup.client.messages.reply(id: targetEmail.id, messageReplyOptions: MessageReplyOptions(text: body))
        
        #expect(!message.id.isEmpty)
        #expect(message.text.body!.contains(body))
    }
    
    @Test("Reply to email as HTML", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func replyHtml() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let body = "<p>Reply <strong>HTML</strong> message.</p>"
        let targetEmail = emails[0]
        
        let message = try await EmailsTestsSetup.client.messages.reply(id: targetEmail.id, messageReplyOptions: MessageReplyOptions(html: body))
        
        #expect(!message.id.isEmpty)
        #expect(message.html.body?.contains(body) == true)
    }
    
    @Test("Reply to email with CC recipient", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func replyWithCc() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()

        let body = "Reply CC Message"
        let targetEmail = emails[0]
        let ccRecipient = "someoneelse@\(EmailsTestsSetup.verifiedDomain ?? "")"
        
        let message = try await EmailsTestsSetup.client.messages.reply(id: targetEmail.id, messageReplyOptions: MessageReplyOptions(html: body, cc: ccRecipient))
        
        #expect(!message.id.isEmpty)
        #expect(message.html.body?.contains(body) == true)
        #expect(message.cc.count == 1)
        #expect(message.cc[0].email == ccRecipient)
    }
    
    @Test("Reply to email with attachment", .enabled(if: EmailsTestsSetup.verifiedDomain != nil))
    func replyWithAttachment() async throws {
        let emails = try await EmailsTestsSetup.ensureInitialized()
        
        let body = "<p>Reply with attachment.</p>"
        let targetEmail = emails[0]
        
        let data = try Data(contentsOf: Bundle.module.url(forResource: "cat", withExtension: "png")!)
        let attachment = MessageAttachmentOptions(contentType: "image/png",
                                                  fileName: "cat.png",
                                                  content: data.base64EncodedString())
        
        let message = try await EmailsTestsSetup.client.messages.reply(id: targetEmail.id, messageReplyOptions: MessageReplyOptions(html: body,
                                                                                                                                    attachments: [attachment]))
        #expect(message.attachments.count == 1)
        let file1 = message.attachments[0]
        #expect(file1.id != nil)
        #expect(file1.length == 82138)
        #expect(file1.url != nil)
        #expect(file1.fileName == "cat.png")
        #expect(file1.contentType == "image/png")
    }
    
    private func validateEmailSummary(email: MessageSummary) {
        validateMetadata(email: email)
        #expect(email.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        #expect(email.attachments == 2)
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
        #expect(email.type == "Email")
        #expect(email.from.count == 1)
        #expect(email.to.count == 1)
        #expect(email.from[0].email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        #expect(email.from[0].name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        #expect(email.to[0].email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        #expect(email.to[0].name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        #expect(email.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        #expect(Date.now.timeIntervalSince(email.received) / 3600 <= 1)
    }
    
    private func validateEmail(email: Message) {
        validateMetadata(email: email)
        validateAttachmentMetadata(email: email)
        validateHtml(email: email)
        validateText(email: email)
        
        #expect(email.metadata.ehlo != nil)
        #expect(email.metadata.mailFrom != nil)
        #expect(email.metadata.rcptTo.count == 1)
    }
    
    private func validateAttachmentMetadata(email: Message) {
        #expect(email.attachments.count == 2)
        
        let file1 = email.attachments[0]
        #expect(file1.id != nil)
        #expect(file1.length == 82138)
        #expect(file1.url != nil)
        #expect(file1.fileName == "cat.png")
        #expect(file1.contentType == "image/png")
        
        let file2 = email.attachments[1]
        #expect(file2.id != nil)
        #expect(file2.length == 212080)
        #expect(file2.url != nil)
        #expect(file2.fileName == "dog.png")
        #expect(file2.contentType == "image/png")
    }
    
    private func validateHtml(email: Message) {
        #expect(email.html.body?.starts(with: "<div dir=\"ltr\">") == true)
        
        #expect(email.html.links.count == 3)
        #expect(email.html.links[0].href == "https://mailosaur.com/")
        #expect(email.html.links[0].text == "mailosaur")
        #expect(email.html.links[1].href == "https://mailosaur.com/")
        #expect(email.html.links[1].text == nil)
        #expect(email.html.links[2].href == "http://invalid/")
        #expect(email.html.links[2].text == "invalid")
        
        #expect(email.html.codes.count == 2)
        #expect(email.html.codes[0].value == "123456")
        #expect(email.html.codes[1].value == "G3H1Y2")
        
        #expect(email.html.images?[1].src.starts(with: "cid:") ?? false)
        #expect(email.html.images?[1].alt == "Inline image 1")
    }
    
    private func validateText(email: Message) {
        #expect(email.text.body?.starts(with: "this is a test") == true)
        
        #expect(email.text.links.count == 2)
        #expect(email.text.links[0].text == email.text.links[0].href)
        #expect(email.text.links[0].text == "https://mailosaur.com/")
        #expect(email.text.links[1].text == email.text.links[1].href)
        #expect(email.text.links[1].text == "https://mailosaur.com/")
        
        #expect(email.text.codes.count == 2)
        #expect(email.text.codes[0].value == "654321")
        #expect(email.text.codes[1].value == "5H0Y2")
    }
    
    private func validateHeaders(email: Message) {
        
    }
}
