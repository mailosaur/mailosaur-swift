//
//  MailosaurError.swift
//  Mailosaur
//
//  Created by Mailosaur on 21.01.2023.
//

public enum MailosaurError: Error {
    case clientUninitialized
    case missingApiKey
    case invalidApiUrl
    case invalidResponse
    case serverError(String)
    case generic(String)

    public var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "'apiKey' must be set. Set the MAILOSAUR_API_KEY environment variable or pass a config with an explicit key."
        default:
            return nil
        }
    }
}
