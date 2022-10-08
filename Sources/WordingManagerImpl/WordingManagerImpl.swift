import Combine
import Core
import Foundation
import Localization
import LocalizationManager
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

    private let decoder = WordingDecoder()
    private let fileManager = FileManager.default

    private var cancellables = [AnyCancellable]()

    init(
        wordingType: W.Type,
        localizationManager: LM,
        provider: WMP
    ) {
        self.wordingType = wordingType
        self.localizationManager = localizationManager
        self.provider = provider
        setWordingForCurrentLocalization()
        subscribeToLanguageChangeEvents()
    }

    private func setWordingForCurrentLocalization() {
        setWording(for: localizationManager.languageSubject.value.localization)
    }

    private func subscribeToLanguageChangeEvents() {
        localizationManager.languageSubject
            .sink { [weak self] language in
                self?.setWording(for: language.localization)
            }
            .store(in: &cancellables)
    }

    private func setWording(for localization: Localization) {
        if localization != .en {
            setWording(for: .en)
        }

        do {
            try setWording(at: provider.bundledWordingURL(for: localization))
        } catch {
            assertionFailure()
        }

        do {
            try setWording(at: provider.persistedWordingURL(for: localization))
        } catch { }
    }

    private func setWording(at wordingURL: URL) throws {
        let wordingData = try Data(contentsOf: wordingURL)
        let wording = try decoder.decode(from: wordingData)
        wordingType.complement(using: wording)
    }

    private func fetchWordingForAllLocalizations() async throws {
        for localization in localizationManager.supportedLocalizations.localizationFirst(
            localizationManager.languageSubject.value.localization
        ) {
            do {
                let wordingData = try await provider.remoteWordingData(for: localization)
                try persistFetchedWordingData(wordingData, for: localization)
            } catch WordingManagerProviderError.remoteWordingIsNotSupported {
                break
            } catch { }
        }
    }

    private func persistFetchedWordingData(
        _ wordingData: Data,
        for localization: Localization
    ) throws {
        let persistedWordingURL = provider.persistedWordingURL(for: localization)
        try fileManager.createDirectory(at: persistedWordingURL.deletingLastPathComponent())
        try wordingData.write(to: persistedWordingURL)
    }

    // MARK: - Startable

    func start() {
        Task {
            do {
                try await fetchWordingForAllLocalizations()
                setWordingForCurrentLocalization()
            } catch { }
        }
    }
}
