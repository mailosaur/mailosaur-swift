//
//  TestEnvironment.swift
//  MailosaurTests
//
//  Created by Mailosaur on 07.07.2026.
//

import Foundation
@testable import Mailosaur

/// A snapshot of the process environment, read exactly once.
///
/// Swift Testing runs suites in parallel, so each suite's `static` setup
/// properties are initialized concurrently. `ProcessInfo.processInfo.environment`
/// is not safe to call from multiple threads at once — under contention it can
/// intermittently return an incomplete dictionary, causing lookups such as
/// `MAILOSAUR_API_KEY` to appear missing. That surfaces as a random suite
/// crashing with `MailosaurError.missingApiKey` (or a force-unwrap trap), and
/// the suite that loses the race changes from run to run.
///
/// Routing every environment read through this single `static let` guarantees
/// the environment is materialised on exactly one thread, exactly once; all
/// suites then read the resulting immutable copy, which is safe to share.
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
