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
        
        let timeout = 120000 // milliseconds
        var pollCount = 0
        let startTime = Date.now
        
        while true {
            let result = await client.performRequest(path: "api/files/screenshots/\(id)", requestType: .data)
            
            switch result {
            case .success(let res):
                guard let httpResponse = res.1 else {
                    return .failure(MailosaurError.invalidResponse)
                }
                
                // Check if we got the data (200 OK)
                if httpResponse.statusCode == 200 {
                    guard let data = res.0 else {
                        return .failure(MailosaurError.invalidResponse)
                    }
                    return .success(data)
                }
                
                // If not 202 Accepted, something went wrong
                if httpResponse.statusCode != 202 {
                    return .failure(MailosaurError.serverError("Unexpected status code: \(httpResponse.statusCode)"))
                }
                
                // Parse delay header
                let delayHeader = httpResponse.value(forHTTPHeaderField: "x-ms-delay") ?? "1000"
                let delayPattern = delayHeader.split(separator: ",").map { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1000 }
                let delay = (pollCount >= delayPattern.count ? delayPattern[delayPattern.count - 1] : delayPattern[pollCount]) / 1000
                
                pollCount += 1
                
                // Stop if timeout will be exceeded
                if (Date.now.timeIntervalSince(startTime) * 1000 + Double(delay * 1000)) > Double(timeout) {
                    return .failure(MailosaurError.generic("An email preview was not generated in time. The email client may not be available, or the preview ID [\(id)] may be incorrect."))
                }
                
                try? await Task.sleep(nanoseconds: UInt64(Double(delay) * Double(NSEC_PER_SEC)))
                
            case .failure(let error):
                return .failure(error)
            }
        }
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
