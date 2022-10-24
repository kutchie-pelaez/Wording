import Core
import Foundation

public protocol WordingManagerProvider {
    func bundledWordingURL(for language: Locale.Language) -> URL
    func persistedWordingURL(for language: Locale.Language) throws -> URL
    func remoteWordingData(for language: Locale.Language) async throws -> Data
}

extension WordingManagerProvider {
    public func persistedWordingURL(for language: Locale.Language) throws -> URL {
        guard let languageIdentifier = language.languageCode?.identifier else {
            throw WordingManagerProviderError.languageIdentifierIsUndefined
        }

        return FileManager.default
            .documents
            .appendingPathComponent("wording")
            .appendingPathComponent("wording_\(languageIdentifier).yml")
    }

    public func remoteWordingData(for language: Locale.Language) async throws -> Data {
        throw WordingManagerProviderError.remoteWordingIsNotSupported
    }
}

enum WordingManagerProviderError: Error {
    case languageIdentifierIsUndefined
    case remoteWordingIsNotSupported
}
