//
//  Files.swift
//  Mailosaur
//
//  Created by Mailosaur on 20.01.2023.
//

import Foundation

public class Files {
    // Must be weak to prevent a retain cycle
    private weak var client: MailosaurClient?
    
    public init(client: MailosaurClient) {
        self.client = client
    }
    
    /// Downloads a single attachment.
    ///
    /// - Parameter id: The identifier for the required attachment.
    public func getAttachmentResult(id: String) async -> Result<Data, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/files/attachments/\(id)", requestType: .data)
    }
    
    /// Downloads a single attachment.
    ///
    /// - Parameter id: The identifier for the required attachment.
    public func getAttachment(id: String) async throws -> Data {
        let result = await self.getAttachmentResult(id: id)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// ownloads an EML file representing the specified email.
    ///
    /// - Parameter id: The identifier for the required message.
    public func getEmailResult(id: String) async -> Result<Data, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/files/email/\(id)", requestType: .data)
    }
    
    /// ownloads an EML file representing the specified email.
    ///
    /// - Parameter id: The identifier for the required message.
    public func getEmail(id: String) async throws -> Data {
        let result = await self.getEmailResult(id: id)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Downloads a screenshot of your email rendered in a real email client. Simply supply
    /// the unique identifier for the required preview.
    ///
    /// - Parameter id: The identifier of the preview to be downloaded.
    public func getPreviewResult(id: String) async -> Result<Data, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/files/previews/\(id)", requestType: .data)
    }
    
    /// Downloads a screenshot of your email rendered in a real email client. Simply supply
    /// the unique identifier for the required preview.
    ///
    /// - Parameter id: The identifier of the preview to be downloaded.
    public func getPreview(id: String) async throws -> Data {
        let result = await self.getPreviewResult(id: id)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
