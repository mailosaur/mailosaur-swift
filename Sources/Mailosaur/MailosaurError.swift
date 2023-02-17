//
//  MailosaurError.swift
//  Mailosaur
//
//  Created by Mailosaur on 21.01.2023.
//

public enum MailosaurError: Error {
    case clientUninitialized
    case invalidApiUrl
    case invalidResponse
    case serverError(String)
    case generic(String)
}
