//
//  UsageModels.swift
//  Mailosaur
//
//  Created by Mailosaur on 20.01.2023.
//

import Foundation

public struct UsageAccountLimit: Decodable {
    /// The limit
    public let limit: Int
    /// The current value
    public let current: Int
}

public struct UsageAccountLimits: Decodable {
    public let servers: UsageAccountLimit
    public let users: UsageAccountLimit
    public let email: UsageAccountLimit
    public let sms: UsageAccountLimit
}

public struct UsageTransaction: Decodable {
    /// Gets or sets the datetime that this transaction occurred.
    public let timestamp: Date
    /// The count of email transactions.
    public let email: Int
    /// The count of SMS transactions.
    public let sms: Int
}

public struct UsageTransactionListResult: Decodable {
    /// Gets or sets the individual transactions forming the result.
    public let items: [UsageTransaction]
}
