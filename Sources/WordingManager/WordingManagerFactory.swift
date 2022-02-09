import LocalizationManager
import Logger
import Wording

public struct WordingManagerFactory {
    public init() { }

    public func produce<Wording>(
        localizationManager: LocalizationManager,
        logger: Logger,
        provider: WordingManagerProvider
    ) -> WordingManagerImpl<Wording> where Wording: Wordingable {
        WordingManagerImpl<Wording>(
            localizationManager: localizationManager,
            logger: logger,
            provider: provider
        )
    }
}
