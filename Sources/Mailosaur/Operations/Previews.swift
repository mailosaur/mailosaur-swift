//
//  Previews.swift
//  Mailosaur
//
//  Created by Mailosaur on 20.01.2023.
//

import Foundation

public class Previews {
    // Must be weak to prevent a retain cycle
    private weak var client: MailosaurClient?
    
    public init(client: MailosaurClient) {
        self.client = client
    }
    
    /// Returns the list of all email clients that can be used to generate email previews.
    public func listEmailClientsResult() async -> Result<EmailClientListResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/screenshots/clients")
    }
    
    /// Returns the list of all email clients that can be used to generate email previews.
    public func listEmailClients() async throws -> EmailClientListResult {
        let result = await self.listEmailClientsResult()
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
