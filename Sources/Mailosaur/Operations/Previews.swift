//
//  Previews.swift
//  Mailosaur
//
//  Created by Mailosaur on 20.01.2023.
//

import Foundation

/// Operations for discovering the email clients available for generating email previews
/// (screenshots of an email rendered in real clients). Accessed via `client.previews`.
public class Previews {
    // Must be weak to prevent a retain cycle
    private weak var client: MailosaurClient?

    public init(client: MailosaurClient) {
        self.client = client
    }

    /// Returns the list of all email clients that can be used to generate email previews.
    ///
    /// - Returns: A `Result` containing an ``EmailClientListResult`` of available email clients on success, or an `Error` on failure.
    public func listEmailClientsResult() async -> Result<EmailClientListResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/screenshots/clients")
    }
    
    /// Returns the list of all email clients that can be used to generate email previews.
    ///
    /// - Returns: An ``EmailClientListResult`` of available email clients.
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
