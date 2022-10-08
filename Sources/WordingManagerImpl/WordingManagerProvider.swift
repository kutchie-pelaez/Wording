import Core
import Foundation
import Localization

public protocol WordingManagerProvider {
    func bundledWordingURL(for localization: Localization) -> URL
    func persistedWordingURL(for localization: Localization) -> URL
    func remoteWordingData(for localization: Localization) async throws -> Data
}

extension WordingManagerProvider {
    public func persistedWordingURL(for localization: Localization) -> URL {
        FileManager.default
            .documents
            .appendingPathComponent("wording")
            .appendingPathComponent("wording_\(localization.identifier).yml")
    }

    public func remoteWordingData(for localization: Localization) async throws -> Data {
        throw WordingManagerProviderError.remoteWordingIsNotSupported
    }
}

enum WordingManagerProviderError: Error {
    case remoteWordingIsNotSupported
}
