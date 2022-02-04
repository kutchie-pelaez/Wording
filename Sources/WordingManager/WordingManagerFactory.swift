import LocalizationManager
import Wording

public struct WordingManagerFactory {
    public init() { }

    public func produce<Wording>(
        localizationManager: LocalizationManager,
        provider: WordingManagerProvider
    ) -> WordingManagerImpl<Wording> where Wording: Wordingable {
        WordingManagerImpl<Wording>(
            localizationManager: localizationManager,
            provider: provider
        )
    }
}
