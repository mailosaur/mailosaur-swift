//
//  DevicesTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 26.01.2023.
//

import XCTest
@testable import Mailosaur

final class DevicesTests: XCTestCase {
    private static var client: MailosaurClient!
    private static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    private static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    
    override class func setUp() {
        super.setUp()
        
        let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))
        self.client = client
    }

    func testCrud() async throws {
        let deviceName = "My Test"
        let sharedSecret = "ONSWG4TFOQYTEMY="
        
        // Create a new device
        let options = DeviceCreateOptions(name: deviceName, sharedSecret: sharedSecret)
        let createDevice = try await Self.client.devices.create(options: options)
        XCTAssertFalse(createDevice.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertEqual(deviceName, createDevice.name)
        
        // Retrieve an otp via device ID
        let otpResult = try await Self.client.devices.otp(query: createDevice.id)
        XCTAssertEqual(6, otpResult.code.count)
        
        let before = try await Self.client.devices.list()
        XCTAssertTrue(before.items.contains { $0.id == createDevice.id })
        
        try await Self.client.devices.delete(id: createDevice.id)
        
        let after = try await Self.client.devices.list()
        XCTAssertFalse(after.items.contains { $0.id == createDevice.id })
    }
    
    func testOtpViaSharedSecret() async throws {
        let sharedSecret = "ONSWG4TFOQYTEMY="
        let result = try await Self.client.devices.otp(query: sharedSecret)
        XCTAssertEqual(6, result.code.count)
    }
}
