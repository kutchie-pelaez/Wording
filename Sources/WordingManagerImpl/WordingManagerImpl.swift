import Core
import Foundation
import LocalizationManager
import Logging
import Wording
import WordingManager

final class WordingManagerImpl<
    W: Wordingable,
    LM: LocalizationManager,
    WMP: WordingManagerProvider
>: WordingManager {
    private let wordingType: W.Type
    private let localizationManager: LM
    private let provider: WMP

    private let currentLanguage = Locale.current.language
    private let logger = Logger(label: "WordingManager")

    init(
        wordingType: W.Type,
        localizationManager: LM,
        provider: WMP
    ) {
        self.wordingType = wordingType
        self.localizationManager = localizationManager
        self.provider = provider
        setWording(for: currentLanguage)
    }

    private func setWording(for language: Locale.Language) {
        let defaultLanguage = localizationManager.defaultLanguage
        let languageIdentifier = safeUndefinedIfNil(language.languageCode?.identifier, "")

        if language != defaultLanguage {
            setWording(for: defaultLanguage)
        }

        do {
            logger.info("Setting bundled wording", metadata: [
                "language": "\(languageIdentifier)"
            ])
            try setWording(at: provider.bundledWordingURL(for: language))
        } catch {
            logger.critical("Failed to set bundled wording", metadata: [
                "language": "\(languageIdentifier)",
                "error": "\(error.localizedDescription)"
            ])
            assertionFailure()
        }

        do {
            logger.info("Setting persisted wording", metadata: [
                "language": "\(languageIdentifier)"
            ])
            try setWording(at: provider.persistedWordingURL(for: language))
        } catch {
            logger.notice("Failed to set persisted wording", metadata: [
                "language": "\(languageIdentifier)",
                "error": "\(error.localizedDescription)"
            ])
        }
    }

    private func setWording(at wordingURL: URL) throws {
        let wordingDecoder = WordingDecoder()
        let wordingData = try Data(contentsOf: wordingURL)
        let wording = try wordingDecoder.decode(from: wordingData)
        wordingType.complement(using: wording)
    }

    private func fetchWordingForAllLanguages() async {
        for language in localizationManager.supportedLanguages.elementFirst(currentLanguage) {
            let languageIdentifier = safeUndefinedIfNil(language.languageCode?.identifier, "")

            do {
                logger.info("Fetching remote wording", metadata: [
                    "language": "\(languageIdentifier)"
                ])
                let wordingData = try await provider.remoteWordingData(for: language)
                try persistFetchedWordingData(wordingData, for: language)
            } catch WordingManagerProviderError.remoteWordingIsNotSupported {
                break
            } catch {
                logger.error("Failed to fetch remote wording", metadata: [
                    "language": "\(languageIdentifier)",
                    "error": "\(error.localizedDescription)"
                ])
            }
        }
    }

    private func persistFetchedWordingData(
        _ wordingData: Data,
        for language: Locale.Language
    ) throws {
        let languageIdentifier = safeUndefinedIfNil(language.languageCode?.identifier, "")
        logger.info("Persisting fetched wording", metadata: [
            "language": "\(languageIdentifier)"
        ])
        let persistedWordingURL = try provider.persistedWordingURL(for: language)
        try FileManager.default.createDirectory(at: persistedWordingURL.deletingLastPathComponent())
        try wordingData.write(to: persistedWordingURL)
    }

    // MARK: - Startable

    func start() {
        Task {
            await fetchWordingForAllLanguages()
            setWording(for: currentLanguage)
        }
    }
}
