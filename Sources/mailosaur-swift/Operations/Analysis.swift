//
//  Analysis.swift
//  mailosaur-swift
//
//  Created by Mailosaur on 19.01.2023.
//

public class Analysis {
    // Must be weak to prevent a retain cycle
    weak var client: MailosaurClient?
    
    public init(client: MailosaurClient) {
        self.client = client
    }
    
    /// Perform a spam analysis of an email.
    ///
    /// - Parameter email: The identifier of the message to be analyzed.
    public func spamResult(email: String) async -> Result<SpamAnalysisResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/analysis/spam/\(email)")
    }
    
    /// Perform a spam analysis of an email.
    ///
    /// - Parameter email: The identifier of the message to be analyzed.
    public func spam(email: String) async throws -> SpamAnalysisResult {
        let result = await self.spamResult(email: email)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
