//
//  Messages.swift
//  Mailosaur
//
//  Created by Mailosaur on 20.01.2023.
//

import Foundation

/// Operations for finding, retrieving, creating, forwarding, replying to, and deleting the
/// email and SMS messages received by your Mailosaur inboxes (servers). Accessed via `client.messages`.
public class Messages {
    // Must be weak to prevent a retain cycle
    private weak var client: MailosaurClient?
    
    public init(client: MailosaurClient) {
        self.client = client
    }
    
    /// Waits for a message to be found, returning as soon as a message matching the specified search criteria is found.
    ///
    ///  - Note: This is the most efficient method of looking up a message, therefore we recommend using it wherever possible.
    ///  - Parameters:
    ///    - server: The unique identifier of the containing inbox (server).
    ///    - criteria: The criteria with which to find messages during a search.
    ///    - timeout: The maximum time, in milliseconds, to wait for a matching message to arrive.
    ///    - receivedAfter: Limits results to messages received after this date. Defaults to one hour ago.
    ///  - Returns: A `Result` containing the first ``Message`` matching the criteria on success, or an `Error` on failure (for example a `MailosaurError.generic` for an invalid inbox (server) ID, or when the search times out).
    public func getResult(server: String, criteria: MessageSearchCriteria? = nil, timeout: Int = 1000, receivedAfter: Date? = nil) async -> Result<Message, Error> {
        let receivedAfterFinal = receivedAfter ?? Calendar.current.date(byAdding: .hour, value: -1, to: Date.now)
        let criteriaFinal = criteria ?? MessageSearchCriteria()
        
        if server.count != 8 { return .failure(MailosaurError.generic("Must provide a valid Server ID.")) }
        let result = await self.searchResult(server: server, criteria: criteriaFinal, page: 0, itemsPerPage: 1, timeout: timeout, receivedAfter: receivedAfterFinal)
        switch result {
        case .success(let res):
            return await self.getByIdResult(id: res.items[0].id)
        case .failure(let error):
            debugPrint(error)
            return .failure(error)
        }
    }
    
    /// Waits for a message to be found, returning as soon as a message matching the specified search criteria is found.
    ///
    ///  - Note: This is the most efficient method of looking up a message, therefore we recommend using it wherever possible.
    ///  - Parameters:
    ///    - server: The unique identifier of the containing inbox (server).
    ///    - criteria: The criteria with which to find messages during a search.
    ///    - timeout: The maximum time, in milliseconds, to wait for a matching message to arrive.
    ///    - receivedAfter: Limits results to messages received after this date. Defaults to one hour ago.
    ///  - Returns: The first ``Message`` matching the criteria.
    ///  - Throws: `MailosaurError.generic` if an invalid inbox (server) ID is supplied, or if no matching message arrives before the timeout elapses (mirrors the API `search_timeout` condition).
    public func get(server: String, criteria: MessageSearchCriteria? = nil, timeout: Int = 1000, receivedAfter: Date? = nil) async throws -> Message {
        let result = await self.getResult(server: server, criteria: criteria, timeout: timeout, receivedAfter: receivedAfter)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Retrieves the detail for a single message. Must be used in conjunction with either list or
    /// search in order to get the unique identifier for the required message.
    ///
    ///  - Parameter id: The unique identifier of the message to be retrieved.
    ///  - Returns: A `Result` containing the full ``Message`` on success, or an `Error` on failure.
    public func getByIdResult(id: String) async -> Result<Message, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/messages/\(id)")
    }
    
    /// Retrieves the detail for a single message. Must be used in conjunction with either list or
    /// search in order to get the unique identifier for the required message.
    ///
    ///  - Parameter id: The unique identifier of the message to be retrieved.
    ///  - Returns: The full ``Message``.
    public func getById(id: String) async throws -> Message {
        let result = await self.getByIdResult(id: id)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Permanently deletes a message. Also deletes any attachments related to the message. This operation cannot be undone.
    ///
    /// - Parameter id: The identifier for the message.
    /// - Returns: A `Result` that is successful once the message has been deleted, or an `Error` on failure.
    public func deleteResult(id: String) async -> Result<(), Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        let result: Result<MailosaurClient.None, Error> = await client.performRequest(path: "api/messages/\(id)", method: .delete)
        return result.map { _ in () }
    }
    
    /// Permanently deletes a message. Also deletes any attachments related to the message. This operation cannot be undone.
    ///
    /// - Parameter id: The identifier for the message.
    /// - Returns: Once the message has been deleted.
    public func delete(id: String) async throws {
        let result = await self.deleteResult(id: id)
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    /// Returns a list of your messages in summary form. The summaries are returned sorted by received date, with the most recently-received messages appearing first.
    ///
    /// - Parameters:
    ///   - server: The unique identifier of the required inbox (server).
    ///   - page: Used in conjunction with `itemsPerPage` to support pagination.
    ///   - itemsPerPage: A limit on the number of results to be returned per page.
    ///   - receivedAfter: Limits results to messages received after this date.
    ///   - dir: Optionally sets the direction of message sorting, either `asc` or `desc`.
    /// - Returns: A `Result` containing a ``MessageListResult`` of message summaries on success, or an `Error` on failure.
    public func listResult(server: String, page: Int? = nil, itemsPerPage: Int? = nil, receivedAfter: Date? = nil, dir: String? = nil) async -> Result<MessageListResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        var queryItems = [URLQueryItem] ()
        
        queryItems.append(URLQueryItem(name: "server", value: server))
        if let page = page { queryItems.append(URLQueryItem(name: "page", value: String(page))) }
        if let itemsPerPage = itemsPerPage { queryItems.append(URLQueryItem(name: "itemsPerPage", value: String(itemsPerPage))) }
        if let receivedAfter = receivedAfter { queryItems.append(URLQueryItem(name: "receivedAfter", value: MailosaurClient.dateFormatter.string(from: receivedAfter))) }
        if let dir = dir { queryItems.append(URLQueryItem(name: "dir", value: dir)) }
        
        return await client.performRequest(path: "api/messages", query: queryItems)
    }
    
    /// Returns a list of your messages in summary form. The summaries are returned sorted by received date, with the most recently-received messages appearing first.
    ///
    /// - Parameters:
    ///   - server: The unique identifier of the required inbox (server).
    ///   - page: Used in conjunction with `itemsPerPage` to support pagination.
    ///   - itemsPerPage: A limit on the number of results to be returned per page.
    ///   - receivedAfter: Limits results to messages received after this date.
    ///   - dir: Optionally sets the direction of message sorting, either `asc` or `desc`.
    /// - Returns: A ``MessageListResult`` containing the message summaries.
    public func list(server: String, page: Int? = nil, itemsPerPage: Int? = nil, receivedAfter: Date? = nil, dir: String? = nil) async throws -> MessageListResult {
        let result = await self.listResult(server: server, page: page, itemsPerPage: itemsPerPage, receivedAfter: receivedAfter, dir: dir)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Permanently delete all messages within an inbox (server). This operation cannot be undone.
    ///
    /// - Parameter server: The unique identifier of the required inbox (server).
    /// - Returns: A `Result` that is successful once all messages within the inbox (server) have been deleted, or an `Error` on failure.
    public func deleteAllResult(server: String) async -> Result<(), Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        var queryItems = [URLQueryItem] ()
        queryItems.append(URLQueryItem(name: "server", value: server))
        
        let result: Result<MailosaurClient.None, Error> = await client.performRequest(path: "api/messages", method: .delete, query: queryItems)
        return result.map { _ in () }
    }
    
    /// Permanently delete all messages within an inbox (server). This operation cannot be undone.
    ///
    /// - Parameter server: The unique identifier of the required inbox (server).
    /// - Returns: Once all messages within the inbox (server) have been deleted.
    public func deleteAll(server: String) async throws {
        let result = await self.deleteAllResult(server: server)
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    /// Returns a list of messages matching the specified search criteria, in summary form.
    /// The messages are returned sorted by received date, with the most recently-received messages appearing first.
    ///
    ///  - Parameters:
    ///    - server: The unique identifier of the inbox (server) to search.
    ///    - criteria: The criteria with which to find messages during a search.
    ///    - page: Used in conjunction with `itemsPerPage` to support pagination.
    ///    - itemsPerPage: A limit on the number of results to be returned per page.
    ///    - timeout: The maximum time, in milliseconds, to wait for a matching message before giving up.
    ///    - receivedAfter: Limits results to messages received after this date.
    ///    - errorOnTimeout: When `true` (the default), a timeout with no results produces a failure; when `false`, an empty result is returned instead.
    ///    - dir: Optionally sets the direction of message sorting, either `asc` or `desc`.
    ///  - Returns: A `Result` containing a ``MessageListResult`` of matching message summaries on success, or an `Error` on failure (including a `MailosaurError.generic` when the search times out and `errorOnTimeout` is `true`).
    public func searchResult(server: String, criteria: MessageSearchCriteria, page: Int? = nil, itemsPerPage: Int? = nil, timeout: Int? = 0, receivedAfter: Date? = nil, errorOnTimeout: Bool = true, dir: String? = nil) async -> Result<MessageListResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        var queryItems = [URLQueryItem] ()
        
        queryItems.append(URLQueryItem(name: "server", value: server))
        if let page = page { queryItems.append(URLQueryItem(name: "page", value: String(page))) }
        if let itemsPerPage = itemsPerPage { queryItems.append(URLQueryItem(name: "itemsPerPage", value: String(itemsPerPage))) }
        if let receivedAfter = receivedAfter { queryItems.append(URLQueryItem(name: "receivedAfter", value: MailosaurClient.dateFormatter.string(from: receivedAfter))) }
        if let dir = dir { queryItems.append(URLQueryItem(name: "dir", value: dir)) }
        
        var pollCount: Int = 0
        let startTime = Date.now
        
        while true {
            let result: Result<MessageListResultWithHeaders, Error> = await client.performRequest(path: "api/messages/search", method: .post, query: queryItems, params: criteria)
            switch result {
            case .success(let res):
                if timeout == nil || timeout == 0 || res.messageListResult.items.count != 0 {
                    return .success(res.messageListResult)
                }
                
                let delayPattern = ((res.delayHeader.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? "1000" : res.delayHeader).split(separator: ",").map { Int($0) ?? 0 }
                let delay = (pollCount >= delayPattern.count ? delayPattern[delayPattern.count - 1] : delayPattern[pollCount]) / 1000
                
                pollCount += 1
                
                if (Date.now.timeIntervalSince(startTime) + Double(delay)) > Double((timeout ?? 0) / 1000) {
                    if errorOnTimeout == false {
                        return .success(res.messageListResult)
                    }
                    
                    return .failure(MailosaurError.generic("No matching messages found in time. By default, only messages received in the last hour are checked (use receivedAfter to override this). The search criteria used for this query was [\(criteria)] which timed out after \((timeout ?? 0) * 10)ms"))
                }
                
                try? await Task.sleep(nanoseconds: UInt64(Double(delay) * Double(NSEC_PER_MSEC)))
                
            case .failure(let error):
                return .failure(error)
            }
        }
    }
    
    /// Returns a list of messages matching the specified search criteria, in summary form.
    /// The messages are returned sorted by received date, with the most recently-received messages appearing first.
    ///
    ///  - Parameters:
    ///    - server: The unique identifier of the inbox (server) to search.
    ///    - criteria: The criteria with which to find messages during a search.
    ///    - page: Used in conjunction with `itemsPerPage` to support pagination.
    ///    - itemsPerPage: A limit on the number of results to be returned per page.
    ///    - timeout: The maximum time, in milliseconds, to wait for a matching message before giving up.
    ///    - receivedAfter: Limits results to messages received after this date.
    ///    - errorOnTimeout: When `true` (the default), a timeout with no results throws; when `false`, an empty result is returned instead.
    ///    - dir: Optionally sets the direction of message sorting, either `asc` or `desc`.
    ///  - Returns: A ``MessageListResult`` containing the matching message summaries.
    ///  - Throws: `MailosaurError.generic` if no matching message is found before the timeout elapses, unless `errorOnTimeout` is set to `false` (mirrors the API `search_timeout` condition).
    public func search(server: String, criteria: MessageSearchCriteria, page: Int? = nil, itemsPerPage: Int? = nil, timeout: Int? = 0, receivedAfter: Date? = nil, errorOnTimeout: Bool = true, dir: String? = nil) async throws -> MessageListResult {
        let result = await self.searchResult(server: server, criteria: criteria, page: page, itemsPerPage: itemsPerPage, timeout: timeout, receivedAfter: receivedAfter, errorOnTimeout: errorOnTimeout, dir: dir)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Creates a new message that can be sent to a verified email address. This is useful
    /// in scenarios where you want an email to trigger a workflow in your product.
    ///
    ///  - Parameters:
    ///    - server: The unique identifier of the required inbox (server).
    ///    - messageCreateOptions: Options to use when creating a new message.
    ///  - Returns: A `Result` containing the newly-created ``Message`` on success, or an `Error` on failure.
    public func createResult(server: String, messageCreateOptions: MessageCreateOptions) async -> Result<Message, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        var queryItems = [URLQueryItem] ()
        queryItems.append(URLQueryItem(name: "server", value: server))
        
        return await client.performRequest(path: "api/messages", method: .post, query: queryItems, params: messageCreateOptions)
    }
    
    /// Creates a new message that can be sent to a verified email address. This is useful
    /// in scenarios where you want an email to trigger a workflow in your product.
    ///
    ///  - Parameters:
    ///    - server: The unique identifier of the required inbox (server).
    ///    - messageCreateOptions: Options to use when creating a new message.
    ///  - Returns: The newly-created ``Message``.
    public func create(server: String, messageCreateOptions: MessageCreateOptions) async throws -> Message {
        let result = await self.createResult(server: server, messageCreateOptions: messageCreateOptions)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Forwards the specified message to a verified email address. This is useful for simulating a user forwarding one of your email messages.
    ///
    ///  - Parameters:
    ///    - id: The unique identifier of the message to be forwarded.
    ///    - messageForwardOptions: Options to use when forwarding a message.
    ///  - Returns: A `Result` containing the forwarded ``Message`` on success, or an `Error` on failure.
    public func forwardResult(id: String, messageForwardOptions: MessageForwardOptions) async -> Result<Message, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/messages/\(id)/forward", method: .post, params: messageForwardOptions)
    }
    
    /// Forwards the specified message to a verified email address. This is useful for simulating a user forwarding one of your email messages.
    ///
    ///  - Parameters:
    ///    - id: The unique identifier of the message to be forwarded.
    ///    - messageForwardOptions: Options to use when forwarding a message.
    ///  - Returns: The forwarded ``Message``.
    public func forward(id: String, messageForwardOptions: MessageForwardOptions) async throws -> Message {
        let result = await self.forwardResult(id: id, messageForwardOptions: messageForwardOptions)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Sends a reply to the specified message. This is useful for when simulating a user replying to one of your email or SMS messages.
    ///
    ///  - Parameters:
    ///    - id: The unique identifier of the message to be replied to.
    ///    - messageReplyOptions: Options to use when replying to a message.
    ///  - Returns: A `Result` containing the reply ``Message`` on success, or an `Error` on failure.
    public func replyResult(id: String, messageReplyOptions: MessageReplyOptions) async -> Result<Message, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/messages/\(id)/reply", method: .post, params: messageReplyOptions)
    }
    
    /// Sends a reply to the specified message. This is useful for when simulating a user replying to one of your email or SMS messages.
    ///
    ///  - Parameters:
    ///    - id: The unique identifier of the message to be replied to.
    ///    - messageReplyOptions: Options to use when replying to a message.
    ///  - Returns: The reply ``Message``.
    public func reply(id: String, messageReplyOptions: MessageReplyOptions) async throws -> Message {
        let result = await self.replyResult(id: id, messageReplyOptions: messageReplyOptions)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Generates screenshots of an email rendered in the specified email clients.
    ///
    ///  - Parameters:
    ///    - id: The identifier of the email to preview.
    ///    - options: The options with which to generate previews.
    ///  - Returns: A `Result` containing a ``PreviewListResult`` of the generated previews on success, or an `Error` on failure.
    public func generatePreviewsResult(id: String, options: PreviewRequestOptions) async -> Result<PreviewListResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/messages/\(id)/screenshots", method: .post, params: options)
    }
    
    /// Generates screenshots of an email rendered in the specified email clients.
    ///
    ///  - Parameters:
    ///    - id: The identifier of the email to preview.
    ///    - options: The options with which to generate previews.
    ///  - Returns: A ``PreviewListResult`` containing the generated previews.
    public func generatePreviews(id: String, options: PreviewRequestOptions) async throws -> PreviewListResult {
        let result = await self.generatePreviewsResult(id: id, options: options)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
