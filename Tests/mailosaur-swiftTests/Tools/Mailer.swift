//
//  Mailer.swift
//  mailosaur-swiftTests
//
//  Created by Mailosaur on 28.01.2023.
//

import Foundation
import mailosaur_swift
import PerfectSMTP

@available(macOS 13.0, *)
class Mailer {
    public static let shared = Mailer()
    
    private static let sHtml: String! = try? String(contentsOf: URL(filePath: Bundle.module.path(forResource: "testEmail", ofType: "html")!))
    private static let sText: String! = try? String(contentsOf: URL(filePath: Bundle.module.path(forResource: "testEmail", ofType: "txt")!))
    
    private static let server = ProcessInfo.processInfo.environment["MAILOSAUR_SERVER"]!
    private static let sVerifiedDomain = ProcessInfo.processInfo.environment["MAILOSAUR_VERIFIED_DOMAIN"] ?? "\(server).mailosaur.net"
    
    public func sendEmail(client: MailosaurClient, server: String, sendToAddress: String? = nil) async throws {
        let host = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_HOST"] ?? "mailosaur.net"
        let port = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_PORT"] ?? "25"
        
        let smtp = SMTPClient(url: "smtp://\(host):\(port)", requiresTLSUpgrade: true)
        let email = EMail(client: smtp)
        
        let randomString = self.getRandomString(length: 10)
        let randomFromAddress = "\(randomString)@\(Self.sVerifiedDomain)"
        let randomToAddress = sendToAddress ?? Servers.generateEmailAddress(serverId: server)
        
        email.from = Recipient(name: "\(randomString) \(randomString)", address: randomFromAddress)
        email.to = [Recipient(name: "\(randomString) \(randomString)", address: randomToAddress)]
        email.subject = "\(randomString) subject"
        email.text = Self.sText.replacingOccurrences(of: "REPLACED_DURING_TEST", with: randomString)
        email.html = Self.sHtml.replacingOccurrences(of: "REPLACED_DURING_TEST", with: randomString)
        email.attachments.append(Attachment(path: Bundle.module.path(forResource: "cat", ofType: "png")!, contentId: "ii_1435fadb31d523f6"))
        email.attachments.append(Attachment(path: Bundle.module.path(forResource: "dog", ofType: "png")!, contentId: "ii_1435fadb31d523f7"))
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try email.send() { code, header, body in
                    print(code)
                    print(header)
                    print(body)
                    continuation.resume(returning: ())
                }
            } catch (let error) {
                print(error)
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func sendEmails(client: MailosaurClient, server: String, quantity: Int) async throws {
        for _ in 0..<quantity {
            try await self.sendEmail(client: client, server: server)
        }
    }
    
    private func getRandomString(length: Int) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}
