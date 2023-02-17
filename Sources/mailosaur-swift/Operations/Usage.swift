//
//  Usage.swift
//  mailosaur-swift
//
//  Created by Mailosaur on 20.01.2023.
//

public class Usage {
    // Must be weak to prevent a retain cycle
    private weak var client: MailosaurClient?
    
    public init(client: MailosaurClient) {
        self.client = client
    }
    
    /// Retrieve account usage limits. Details the current limits and usage for your account. This endpoint requires authentication with an account-level API key.
    public func limitsResult() async -> Result<UsageAccountLimits, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/usage/limits")
    }
    
    /// Retrieve account usage limits. Details the current limits and usage for your account. This endpoint requires authentication with an account-level API key.
    public func limits() async throws -> UsageAccountLimits {
        let result = await self.limitsResult()
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Retrieves the last 31 days of transactional usage. This endpoint requires authentication with an account-level API key.
    public func transactionsResult() async -> Result<UsageTransactionListResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/usage/transactions")
    }
    
    /// Retrieves the last 31 days of transactional usage. This endpoint requires authentication with an account-level API key.
    public func transactions() async throws -> UsageTransactionListResult {
        let result = await self.transactionsResult()
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
