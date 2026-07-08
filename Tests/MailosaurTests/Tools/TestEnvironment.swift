//
//  TestEnvironment.swift
//  MailosaurTests
//
//  Created by Mailosaur on 07.07.2026.
//

import Foundation
@testable import Mailosaur

enum TestEnvironment {
    static let values = ProcessInfo.processInfo.environment

    static subscript(_ key: String) -> String? { values[key] }

    static let apiBaseUrl = values["MAILOSAUR_BASE_URL"]!
    static let apiKey = values["MAILOSAUR_API_KEY"]!
    static let server = values["MAILOSAUR_SERVER"]!
    static let verifiedDomain = values["MAILOSAUR_VERIFIED_DOMAIN"]

    /// Builds a client from the cached snapshot, avoiding the throwing
    /// `MailosaurClient(baseUrl:)` convenience initializer, which reads the
    /// environment again on each call and reintroduces the race.
    static func makeClient() -> MailosaurClient {
        MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
    }
}
