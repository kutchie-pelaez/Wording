import LocalizationManager
import Wording

public struct WordingManagerFactory<Wording> where Wording: Wordingable {
    public init() { }

    public func produce(
        localizationManager: LocalizationManager,
        provider: WordingManagerProvider
    ) -> WordingManager<Wording> {
        WordingManager(
            localizationManager: localizationManager,
            provider: provider
        )
    }
}
