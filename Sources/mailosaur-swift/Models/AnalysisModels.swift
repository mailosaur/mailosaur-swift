//
//  AnalysisModels.swift
//  mailosaur-swift
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
