import Combine
import Core
import Foundation
import Language
import LocalizationManager
import Wording
import WordingManager
import Yams

final class WordingManagerImpl<
    W: Wordingable,
    LM: LocalizationManager,
    WMP: WordingManagerProvider
>: WordingManager {
    private struct WordingDecoder {
        private let ymlDecoder = YAMLDecoder()

        func decode(from data: Data) throws -> W {
            try ymlDecoder.decode(W.self, from: data)
        }
    }

    private struct WordingEncoder {
        private let ymlEncoder = YAMLEncoder()

        func encode(_ wording: W) throws -> Data {
            let ymlString = try ymlEncoder.encode(wording)

            return safeUndefinedIfNil(
                ymlString.data(using: .utf8),
                Data()
            )
        }
    }

    private let localizationManager: LM
    private let provider: WMP

    private var cancellables = [AnyCancellable]()

    private var cache = [Localization: W]()
    private let wordingDecoder = WordingDecoder()
    private let wordingEncoder = WordingEncoder()

    private lazy var _wordingSubject = MutableValueSubject<W>(
        wording(for: localizationManager.languageSubject.value.localization)
    )

    init(
        localizationManager: LM,
        provider: WMP
    ) {
        self.localizationManager = localizationManager
        self.provider = provider
        populateCahceWithBundledWording()
        populateCahceWithPersistedWording()
        subscribeToEvents()
        Task {
            try await fetchWordingForAllLocalizations()
        }
    }

    private func syncWording(for localization: Localization) {
        let newWording = wording(for: localization)
        _wordingSubject.value = newWording
    }

    private func populateCahceWithBundledWording() {
        populateCacheForAllLocalizations(
            provider.wordingBundledURL,
            assertOnFailure: true
        )
    }

    private func populateCahceWithPersistedWording() {
        populateCacheForAllLocalizations(
            provider.wordingPersistedURL,
            assertOnFailure: false
        )
    }

    private func subscribeToEvents() {
        localizationManager.languageSubject
            .sink { [weak self] newLanguage in
                self?.syncWording(for: newLanguage.localization)
            }
            .store(in: &cancellables)
    }

    private func populateCacheForAllLocalizations(
        _ urlAccessor: (Localization) -> URL,
        assertOnFailure: Bool
    ) {
        for localization in localizationManager.supportedLocalizations.englishFirst {
            do {
                try populateCache(
                    from: urlAccessor(localization),
                    for: localization
                )
            } catch {
                if assertOnFailure {
                    assertionFailure()
                }

                continue
            }
        }
    }

    private func populateCache(
        from url: URL,
        for localization: Localization
    ) throws {
        let data = try Data(contentsOf: url)
        var wording = try wordingDecoder.decode(from: data)

        mutateWordingWithFallbacks(&wording, using: localization)
        cache[localization] = wording
    }

    private func mutateWordingWithFallbacks(
        _ wording: inout W,
        using localization: Localization
    ) {
        if
            localization != .en,
            let cachedLocalizedWording = cache[localization]
        {
            wording.mutate(using: cachedLocalizedWording)
        }

        if let cachedEnWording = cache[.en] {
            wording.mutate(using: cachedEnWording)
        }
    }

    private func wording(for localization: Localization) -> W {
        safeUndefinedIfNil(
            cache[localization],
            undefinedIfNil(
                cache[.en],
                "Failed to get cached en wording"
            ),
            "Failed to get cached wording for \(localization) localization"
        )
    }

    private func fetchWordingForAllLocalizations() async throws {
        for localization in localizationManager.supportedLocalizations.localizationFirst(localizationManager.languageSubject.value.localization) {
            do {
                let wording = try await fetchWording(for: localization)

                try persistFetchedWording(
                    wording,
                    for: localization
                )

                cache[localization] = wording
                syncWording(for: localization)
            } catch WordingManagerProviderError.noRemoteWordingSupported {
                break
            }
        }
    }

    private func fetchWording(for localization: Localization) async throws -> W {
        let wordingData = try await provider.wordingRemoteData(for: localization)
        var wording = try wordingDecoder.decode(from: wordingData)

        mutateWordingWithFallbacks(&wording, using: localization)

        return wording
    }

    private func persistFetchedWording(
        _ wording: W,
        for localization: Localization
    ) throws {
        let url = provider.wordingPersistedURL(for: localization)
        let data = try wordingEncoder.encode(wording)

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url)
    }

    // MARK: - WordingManager

    public var wordingSubject: ValueSubject<W> { _wordingSubject }
}
