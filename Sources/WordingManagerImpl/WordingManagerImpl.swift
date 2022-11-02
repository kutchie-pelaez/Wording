import Core
import Foundation
import LocalizationManager
import Logging
import Undefined
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
    private let logger = Logger(label: "Wording")

    init(wordingType: W.Type, localizationManager: LM, provider: WMP) {
        self.wordingType = wordingType
        self.localizationManager = localizationManager
        self.provider = provider
        setWording(for: currentLanguage)
    }

    private func setWording(for language: Locale.Language) {
        let defaultLanguage = localizationManager.defaultLanguage
        let languageCodeIdentifier = languageCodeIdentifier(for: language)

        if language != defaultLanguage {
            setWording(for: defaultLanguage)
        }

        do {
            logger.info("Setting bundled wording", metadata: [
                "language": "\(languageCodeIdentifier)"
            ])
            try setWording(at: provider.bundledWordingURL(for: language))
        } catch {
            logger.critical("Failed to set bundled wording", metadata: [
                "language": "\(languageCodeIdentifier)",
                "error": "\(error)"
            ])
            assertionFailure()
        }

        do {
            logger.info("Setting persisted wording", metadata: [
                "language": "\(languageCodeIdentifier)"
            ])
            try setWording(at: provider.persistedWordingURL(for: language))
        } catch {
            logger.notice("Failed to set persisted wording", metadata: [
                "language": "\(languageCodeIdentifier)",
                "error": "\(error)"
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
        for language in localizationManager.supportedLanguages.reorderingElementFirst(currentLanguage) {
            let languageCodeIdentifier = languageCodeIdentifier(for: language)
            do {
                logger.info("Fetching remote wording", metadata: [
                    "language": "\(languageCodeIdentifier)"
                ])
                let wordingData = try await provider.remoteWordingData(for: language)
                try persistFetchedWordingData(wordingData, for: language)
            } catch WordingManagerProviderError.remoteWordingIsNotSupported {
                break
            } catch {
                logger.error("Failed to fetch remote wording", metadata: [
                    "language": "\(languageCodeIdentifier)",
                    "error": "\(error)"
                ])
            }
        }
    }

    private func persistFetchedWordingData(_ wordingData: Data, for language: Locale.Language) throws {
        logger.info("Persisting fetched wording", metadata: [
            "language": "\(languageCodeIdentifier(for: language))"
        ])
        let persistedWordingURL = try provider.persistedWordingURL(for: language)
        try FileManager.default.createDirectory(at: persistedWordingURL.deletingLastPathComponent())
        try wordingData.write(to: persistedWordingURL)
    }

    // MARK: Startable

    func start() {
        Task {
            await fetchWordingForAllLanguages()
            setWording(for: currentLanguage)
        }
    }
}

private func languageCodeIdentifier(for language: Locale.Language) -> String {
    safeUndefinedIfNil(
        language.languageCode?.identifier,
        fallback: "en",
        message: "Null language code identefier",
        metadata: [
            "languageMaximalIdentifier": language.maximalIdentifier
        ]
    )
}
