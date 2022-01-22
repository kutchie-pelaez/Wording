import LocalizationManager
import Wording

public struct WordingManagerFactory {
    public init() { }

    public func produce<Wording>(
        localizationManager: LocalizationManager,
        provider: WordingManagerProvider
    ) -> WordingManager<Wording> where Wording: Wordingable {
        WordingManager<Wording>(
            localizationManager: localizationManager,
            provider: provider
        )
    }
}
