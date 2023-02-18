//
//  MailosaurClient.swift
//  Mailosaur
//
//  Created by Mailosaur on 19.01.2023.
//

import Foundation

public class MailosaurClient {
    private let config: MailosaurConfig
    private let defaultBaseUrl = URL(string: "https://mailosaur.com/")!
    
    static var dateFormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withFullDate,
            .withFullTime,
            .withFractionalSeconds
        ]
        return formatter
    } ()
    
    private static var urlSession: URLSession = {
        var configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: configuration)
    } ()
    
    static var dateFormatter = ISO8601DateFormatter()
    
    private let apiResponseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = dateFormatter.date(from: dateString) {
                return date
            } else if let date = dateFormatterWithFractionalSeconds.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            
        })
        return decoder
    } ()
    
    private let apiOptionEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom({ date, encoder in
            var container = encoder.singleValueContainer()
            let dateString = dateFormatterWithFractionalSeconds.string(from: date)
            try container.encode(dateString)
        })
        return encoder
    } ()
    
    public enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    public enum RequestType {
        case json
        case data
    }
    
    struct None: Decodable { }
    
    public lazy var analysis: Analysis = {
        Analysis(client: self)
    } ()
    public lazy var devices: Devices = {
        Devices(client: self)
    } ()
    public lazy var files: Files = {
        Files(client: self)
    } ()
    public lazy var messages: Messages = {
        Messages(client: self)
    } ()
    public lazy var servers: Servers = {
        Servers(client: self)
    } ()
    public lazy var usage: Usage = {
        Usage(client: self)
    } ()
    
    public init(config: MailosaurConfig) {
        self.config = config
    }
    
    public func performRequest(path: String, method: Method = .get, requestType: RequestType = .json, query: [URLQueryItem]? = nil, params: Encodable? = nil) async -> Result<(Data?, HTTPURLResponse?), Error> {
        do {
            guard let baseUrl = URL(string: path, relativeTo: self.config.baseUrl ?? self.defaultBaseUrl) else { return .failure(MailosaurError.invalidApiUrl) }
            var requestUrlComponents =  URLComponents(url: baseUrl, resolvingAgainstBaseURL: true)
            requestUrlComponents?.queryItems = query
            guard let requestUrl = requestUrlComponents?.url else { return .failure(MailosaurError.invalidApiUrl) }
            
            let encodedApiKey = Data("\(self.config.apiKey):".utf8).base64EncodedString()
            var request = URLRequest(url: requestUrl)
            request.httpMethod = method.rawValue
            if requestType == .json {
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            request.setValue("mailosaur-swift/\(MailosaurConfig.clientVersion)", forHTTPHeaderField: "User-Agent")
            request.setValue("Basic \(encodedApiKey)", forHTTPHeaderField: "Authorization")
            
            if let params = params {
                request.httpBody = try? self.apiOptionEncoder.encode(params)
            }
            
            let (data, response) = try await Self.urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return .failure(MailosaurError.invalidResponse) }
            
            switch httpResponse.statusCode {
            case 200:
                return .success((data, httpResponse))
            case 204:
                switch requestType {
                case .json:
                    return .success((nil, nil))
                case .data:
                    return .failure(MailosaurError.invalidResponse)
                }
            case 400:
                let json = try self.apiResponseDecoder.decode(BadRequestErrors.self, from: data)
                let message = json.errors.map { "(\($0.field)) \($0.detail.first?.description ?? "")" }.joined(separator: "\r\n")
                return .failure(MailosaurError.serverError(message))
            case 401:
                return .failure(MailosaurError.serverError("Authentication failed, check your API key."))
            case 403:
                return .failure(MailosaurError.serverError("Insufficient permission to perform that task."))
            case 404:
                return .failure(MailosaurError.serverError("Not found, check input parameters."))
            default:
                return .failure(MailosaurError.serverError("An API error occurred (\(httpResponse.statusCode)"))
            }
        } catch (let error) {
            return .failure(error)
        }
    }
    
    public func performRequest<T: Decodable>(path: String, method: Method = .get, requestType: RequestType = .json, query: [URLQueryItem]? = nil, params: Encodable? = nil) async -> Result<T, Error> {
        do {
            let result = await self.performRequest(path: path, method: method, requestType: requestType, query: query, params: params)
            switch result {
            case .success(let res):
                if requestType == .data {
                    return .success(res.0 as! T)
                }
                if let data = res.0, let response = res.1  {
                    if T.self == MessageListResultWithHeaders.self{
                        let delay = response.value(forHTTPHeaderField: "x-ms-delay") ?? "0"
                        let jsonResult = MessageListResultWithHeaders(messageListResult: try self.apiResponseDecoder.decode(MessageListResult.self, from: data), delayHeader: delay) as! T
                        return .success(jsonResult)
                    }
                    let jsonResult = try self.apiResponseDecoder.decode(T.self, from: data)
                    return .success(jsonResult)
                }
                return .success(None() as! T)
            case .failure(let error):
                debugPrint(error)
                return .failure(error)
            }
        } catch (let error) {
            debugPrint(error)
            return .failure(error)
        }
    }
}
