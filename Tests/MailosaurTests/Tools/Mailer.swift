//
//  Mailer.swift
//  MailosaurTests
//
//  Created by Mailosaur on 28.01.2023.
//

import Foundation
import NIO
import Mailosaur
import SwiftSMTP

class Mailer {
    public static let shared = Mailer()
    
    private static let sHtml: String! = try? String(contentsOf: Bundle.module.url(forResource: "testEmail", withExtension: "html")!)
    private static let sText: String! = try? String(contentsOf: Bundle.module.url(forResource: "testEmail", withExtension: "txt")!)
    
    private static let server = ProcessInfo.processInfo.environment["MAILOSAUR_SERVER"]!
    private static let sVerifiedDomain = ProcessInfo.processInfo.environment["MAILOSAUR_VERIFIED_DOMAIN"] ?? "\(server).mailosaur.net"
    
    public func sendEmail(client: MailosaurClient, server: String, sendToAddress: String? = nil) async throws {
        let host = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_HOST"] ?? "mailosaur.net"
        let port = ProcessInfo.processInfo.environment["MAILOSAUR_SMTP_PORT"] ?? "25"
        
        // let smtp = SMTPClient(url: "smtp://\(host):\(port)", requiresTLSUpgrade: true)
        let smtpConfig = Configuration(server: .init(hostname: host, 
                                         port: Int(port),
                                         encryption: .startTLS(.ifAvailable)),
                           connectionTimeOut: .seconds(5),
                           featureFlags: [.base64EncodeAllMessages, .maximumBase64LineLength64])

        let evg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let mailer = SwiftSMTP.Mailer(group: evg, configuration: smtpConfig)
        
        let randomString = self.getRandomString(length: 10)
        let randomName = "\(randomString) \(randomString)"
        let randomFromAddress = "\(randomString)@\(Self.sVerifiedDomain)"
        let randomToAddress = sendToAddress ?? Servers.generateEmailAddress(serverId: server)
        
        let plainText = Self.sText.replacingOccurrences(of: "REPLACED_DURING_TEST", with: randomString)
        let htmlText = Self.sHtml.replacingOccurrences(of: "REPLACED_DURING_TEST", with: randomString)

        let cat = try Data(contentsOf: Bundle.module.url(forResource: "cat", withExtension: "png")!)
        let dog = try Data(contentsOf: Bundle.module.url(forResource: "dog", withExtension: "png")!)

        let email = Email(sender: .init(name: randomName, emailAddress: randomFromAddress),
                  replyTo: nil,
                  recipients: [
                    .init(name: randomName, emailAddress: randomToAddress),
                  ],
                  subject: "\(randomString) subject",
                  body: .universal(plain: plainText, html: htmlText),
                  attachments: [
                    .init(name: "cat.png",
                          contentType: "image/png",
                          data: cat),
                    .init(name: "dog.png",
                          contentType: "image/png",
                          data: dog)
                  ])
        
        func _send(_ email: Email) async throws {
            try await mailer.send(email)
        }
        
        do {
            print("Sending mail...")
            try await _send(email)
            print("Successfully sent mail!")
        } catch {
            print("Failed sending: \(error)")
        }
        do {
            try await evg.shutdownGracefully()
        } catch {
            print("Failed shutdown: \(error)")
        }
    }
    
    public func sendEmails(client: MailosaurClient, server: String, quantity: Int) async throws {
        for _ in 0..<quantity {
            try await self.sendEmail(client: client, server: server)
        }
    }
    
    public func getRandomString(length: Int) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}
