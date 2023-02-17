//
//  DevicesModels.swift
//  mailosaur-swift
//
//  Created by Mailosaur on 20.01.2023.
//

import Foundation

public struct Device: Decodable {
    /// Unique identifier for the device.
    public let id: String
    /// The name of the device.
    public let name: String
}

public struct DeviceListResult: Decodable {
    /// Gets or sets the individual devices forming the result.
    public let items: [Device]
}

public struct DeviceCreateOptions: Encodable {
    /// A name used to identify the device.
    public let name: String
    /// The base32-encoded shared secret for this device.
    public let sharedSecret: String
}

public struct OtpResult: Decodable {
    /// The current one-time password.
    public let code: String
    /// The expiry date/time of the current one-time password.
    public let expires: Date
}

internal struct OtpSharedOptions: Encodable {
    public let sharedSecret: String
}
