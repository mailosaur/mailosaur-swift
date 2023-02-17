//
//  ErrorModels.swift
//  Mailosaur
//
//  Created by Mailosaur on 27.01.2023.
//


public struct BadRequestErrors: Decodable {
    public let status: Int
    public let errors: [BadRequestError]
}

public struct BadRequestError: Decodable {
    public let field: String
    public let detail: [BadRequestErrorDetail]
}

public struct BadRequestErrorDetail: Decodable {
    public let description: String
    public let code: String
}
