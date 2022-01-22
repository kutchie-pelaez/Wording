import Combine
import CoreUtils
import Foundation
import Language
import LocalizationManager
import Wording
import os

private let logger = Logger("wording")

public final class WordingManager<Wording>: Startable where Wording: Wordingable {
    init(
        localizationManager: LocalizationManager,
        provider: WordingManagerProvider
    ) {
        self.localizationManager = localizationManager
        self.provider = provider
        populateCahceWithBundledWording()
        populateCahceWithPersistedWording()
        subscribeToEvents()
    }

    private typealias WordingBlock = (Wording) -> ()

    private let localizationManager: LocalizationManager
    private unowned let provider: WordingManagerProvider

    private let eventPassthroughSubject = PassthroughSubject<WordingEvent, Never>()
    private var cancellables = [AnyCancellable]()
    private var receivers = WeakArray<WordingBlock>()

    private var cache = [Localization: Wording]()
    private let decoder = WordingDecoder<Wording>()
    private let encoder = WordingEncoder<Wording>()

    // MARK: - Subscribe to events

    private func subscribeToEvents() {
        let languageDidChangeEvents = localizationManager.eventPublisher
            .filter { event in
                if case .languageDidChange = event {
                    return true
                }

                return false
            }
            .asVoid()

        let wordingDidFetchedEvents = eventPublisher
            .filter { [weak self] event in
                if
                    case let .wordingDidFetch(localization) = event,
                    localization == self?.localizationManager.language.localization
                {
                    return true
                }

                return false
            }
            .asVoid()

        Publishers
            .Merge(
                languageDidChangeEvents,
                wordingDidFetchedEvents
            )
            .sink { [weak self] in
                self?.notifyRecieversWithCurrentWording()
            }
            .store(in: &cancellables)
    }

    private func notifyRecieversWithCurrentWording() {
        receivers.forEach {
            $0(wording)
        }
    }

    // MARK: - Initial cache populating

    private func populateCahceWithBundledWording() {
        populateCacheForAllLocalizations(
            provider.wordingBundledURL,
            wordingType: .bundled,
            assertOnFailure: true
        )
    }

    private func populateCahceWithPersistedWording() {
        populateCacheForAllLocalizations(
            provider.wordingPersistedURL,
            wordingType: .persisted,
            assertOnFailure: false
        )
    }

    private func populateCacheForAllLocalizations(
        _ urlAccessor: (Localization) -> URL,
        wordingType: WordingType,
        assertOnFailure: Bool
    ) {
        for localization in localizationManager.supportedLocalizations.englishFirst {
            do {
                try populateCache(
                    from: urlAccessor(localization),
                    for: localization
                )

                logger.log("Successfully populate cache with \(wordingType) wording for \(localization) localization")
            } catch let error {
                logger.error("Failed to populate cache with \(wordingType) wording for \(localization) localization: \(error.localizedDescription)")

                if assertOnFailure {
                    appAssertionFailure()
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
        var wording = try decoder.decode(from: data)

        mutateWordingWithFallbacks(&wording, using: localization)
        cache[localization] = wording
    }

    // MARK: - Providing fallback

    private func mutateWordingWithFallbacks(
        _ wording: inout Wording,
        using localization: Localization
    ) {
        if let localizedWorindgInCache = cache[localization] {
            wording.mutate(using: localizedWorindgInCache)
        }
        if let enWorindgInCache = cache["en"] {
            wording.mutate(using: enWorindgInCache)
        }
    }

    // MARK: - Fetching & persisting

    private func fetchWordingForAllLocalizations() {
        for localization in localizationManager.supportedLocalizations.englishFirst {
            Task {
                do {
                    let wording = try await fetchWording(for: localization)

                    try persistFetchedWording(wording, for: localization)
                    cache[localization] = wording
                    eventPassthroughSubject.send(.wordingDidFetch(localization))
                } catch let error {
                    logger.error("Failed to update wording for \(localization) localization: \(error.localizedDescription)")
                }
            }
        }
    }

    private func fetchWording(for localization: Localization) async throws -> Wording {
        logger.log("Fetching wording for \(localization) localization")

        let wordingData = try await provider.wordingRemoteData(for: localization)
        var wording = try decoder.decode(from: wordingData)

        logger.log("Successfully fetched wording for \(localization) localization")
        mutateWordingWithFallbacks(&wording, using: localization)

        return wording
    }

    private func persistFetchedWording(
        _ wording: Wording,
        for localization: Localization
    ) throws {
        let url = provider.wordingPersistedURL(for: localization)
        let data = try encoder.encode(wording)

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url)
    }

    // MARK: - Startable

    public func start() {
        fetchWordingForAllLocalizations()
    }

    // MARK: - Public interface

    public var wording: Wording {
        wording(for: localizationManager.language.localization)
    }

    public var eventPublisher: ValuePublisher<WordingEvent> {
        eventPassthroughSubject
            .eraseToAnyPublisher()
    }

    public func wording(for localization: Localization) -> Wording {
        undefinedIfNil(
            cache[localization],
            "Failed to get cached wording for \(localization) localization"
        )
    }

    public func register<Receiver>(wordingReceiver: Receiver) where Receiver: WordingReceiver, Receiver.Wording == Wording {
        wordingReceiver.receive(wording)

        let objectReceiver = wordingReceiver as AnyObject
        receivers.append(
            { [weak objectReceiver] wording in
                (objectReceiver as? Receiver)?.receive(wording)
            }
        )
    }
}
