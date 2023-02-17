//
//  Devices.swift
//  mailosaur-swift
//
//  Created by Mailosaur on 20.01.2023.
//

public class Devices {
    // Must be weak to prevent a retain cycle
    private weak var client: MailosaurClient?
    
    public init(client: MailosaurClient) {
        self.client = client
    }
    
    /// Returns a list of your virtual security devices.
    public func listResult() async -> Result<DeviceListResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/devices")
    }
    
    /// Returns a list of your virtual security devices.
    public func list() async throws -> DeviceListResult {
        let result = await self.listResult()
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Creates a new virtual security device.
    ///
    /// - Parameter options: Options used to create a new Mailosaur virtual security device.
    public func createResult(options: DeviceCreateOptions) async -> Result<Device, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        return await client.performRequest(path: "api/devices",
                                           method: .post,
                                           params: DeviceCreateOptions(name: options.name,
                                                                       sharedSecret: options.sharedSecret))
    }
    
    /// Creates a new virtual security device.
    ///
    /// - Parameter options: Options used to create a new Mailosaur virtual security device.
    public func create(options: DeviceCreateOptions) async throws -> Device {
        let result = await self.createResult(options: options)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Retrieves the current one-time password for a saved device, or given base32-encoded shared secret.
    ///
    /// - Parameter query: Either the unique identifier of the device, or a base32-encoded shared secret.
    public func otpResult(query: String) async -> Result<OtpResult, Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        if query.contains("-") {
            return await client.performRequest(path: "api/devices/\(query)/otp")
        }
        return await client.performRequest(path: "api/devices/otp", method: .post, params: OtpSharedOptions(sharedSecret: query))
    }
    
    /// Retrieves the current one-time password for a saved device, or given base32-encoded shared secret.
    ///
    /// - Parameter query: Either the unique identifier of the device, or a base32-encoded shared secret.
    public func otp(query: String) async throws -> OtpResult {
        let result = await self.otpResult(query: query)
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    /// Permanently delete a virtual security device. This operation cannot be undone.
    ///
    /// - Parameter id: The unique identifier of the device.
    public func deleteResult(id: String) async -> Result<(), Error> {
        guard let client = self.client else { return .failure(MailosaurError.clientUninitialized) }
        let result: Result<MailosaurClient.None, Error> = await client.performRequest(path: "api/devices/\(id)", method: .delete)
        return result.map { _ in () }
    }
    
    /// Permanently delete a virtual security device. This operation cannot be undone.
    ///
    /// - Parameter id: The unique identifier of the device.
    public func delete(id: String) async throws {
        let result = await self.deleteResult(id: id)
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
