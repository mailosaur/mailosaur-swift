//
//  DevicesTests.swift
//  MailosaurTests
//
//  Created by Mailosaur on 26.01.2023.
//

import Foundation
import Testing
@testable import Mailosaur

@Suite("Device Management Tests", .serialized)
struct DevicesTests {
    private static let apiKey = ProcessInfo.processInfo.environment["MAILOSAUR_API_KEY"]!
    private static let apiBaseUrl = ProcessInfo.processInfo.environment["MAILOSAUR_BASE_URL"]!
    private static let client = MailosaurClient(config: MailosaurConfig(apiKey: apiKey, baseUrl: URL(string: apiBaseUrl)!))

    @Test("Create, retrieve, and delete device")
    func crud() async throws {
        let deviceName = "My Test"
        let sharedSecret = "ONSWG4TFOQYTEMY="
        
        // Create a new device
        let options = DeviceCreateOptions(name: deviceName, sharedSecret: sharedSecret)
        let createDevice = try await Self.client.devices.create(options: options)
        #expect(!createDevice.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        #expect(createDevice.name == deviceName)
        
        // Retrieve an otp via device ID
        let otpResult = try await Self.client.devices.otp(query: createDevice.id)
        #expect(otpResult.code.count == 6)
        
        let before = try await Self.client.devices.list()
        #expect(before.items.contains { $0.id == createDevice.id })
        
        try await Self.client.devices.delete(id: createDevice.id)
        
        let after = try await Self.client.devices.list()
        #expect(!after.items.contains { $0.id == createDevice.id })
    }
    
    @Test("Generate OTP via shared secret")
    func otpViaSharedSecret() async throws {
        let sharedSecret = "ONSWG4TFOQYTEMY="
        let result = try await Self.client.devices.otp(query: sharedSecret)
        #expect(result.code.count == 6)
    }
}
