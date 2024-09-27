//
//  AnalysisModels.swift
//  Mailosaur
//
//  Created by Mailosaur on 20.01.2023.
//

public struct SpamAssassinRule: Decodable {
    public let score: Double?
    public let rule: String
    public let description: String
}

public struct SpamFilterResults: Decodable {
    public let spamAssassin: [SpamAssassinRule]
}

public struct SpamAnalysisResult: Decodable {
    public let spamFilterResults: SpamFilterResults
    public let score: Double?
}


public struct DeliverabilityReport: Decodable {
    public let spf: EmailAuthenticationResult?
    public let dkim: [EmailAuthenticationResult]
    public let dmarc: EmailAuthenticationResult?
    public let blockLists: [BlockListResult]
    public let content: Content
    public let dnsRecords: DnsRecords
    public let spamAssassin: SpamAssassinResult
}

public struct EmailAuthenticationResult: Decodable {
    public let result: ResultEnum
    public let description: String?
    public let rawValue: String?
    public let tags: [String: String]?
}

public struct BlockListResult: Decodable {
    public let id: String
    public let name: String
    public let result: ResultEnum
}

public struct Content: Decodable {
    public let embed: Bool
    public let iframe: Bool
    public let object: Bool
    public let script: Bool
    public let shortUrls: Bool
    public let textSize: Int
    public let totalSize: Int
    public let missingAlt: Bool
    public let missingListUnsubscribe: Bool
}

public struct DnsRecords: Decodable {
    public let a: [String]?
    public let mx: [String]?
    public let ptr: [String]?
}

public struct SpamAssassinResult: Decodable {
    public let score: Double?
    public let result: ResultEnum
    public let rules: [SpamAssassinRule]
}

public enum ResultEnum: String, Decodable {
    case Pass = "Pass"
    case Warning = "Warning"
    case Fail = "Fail"
    case Timeout = "Timeout"
}
