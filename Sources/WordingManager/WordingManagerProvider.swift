import CoreUtils
import Foundation
import Language

public protocol WordingManagerProvider: AnyObject {
    func wordingBundledURL(for localization: Localization) -> URL
    func wordingPersistedURL(for localization: Localization) -> URL
    func wordingRemoteData(for localization: Localization) async throws -> Data
}

extension WordingManagerProvider {
    public func wordingPersistedURL(for localization: Localization) -> URL {
        FileManager.default
            .documents
            .appendingPathComponent("wording")
            .appendingPathComponent("wording_\(localization.identifier).yml")
    }

    public func wordingRemoteData(for localization: Localization) async throws -> Data {
        throw WordingManagerProviderError.noRemoteWordingSupported
    }
}
