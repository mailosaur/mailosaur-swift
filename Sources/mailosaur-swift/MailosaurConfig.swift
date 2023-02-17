//
//  MailosaurConfig.swift
//  mailosaur-swift
//
//  Created by Mailosaur on 23.01.2023.
//

import Foundation

public struct MailosaurConfig {
    public let apiKey: String
    public let baseUrl: URL?
    
    public init(apiKey: String, baseUrl: URL) {
        self.apiKey = apiKey
        self.baseUrl = baseUrl
    }
    
    public init(apiKey: String) {
        self.apiKey = apiKey
        self.baseUrl = nil
    }
}
