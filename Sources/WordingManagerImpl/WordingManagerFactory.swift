import LocalizationManager
import Wording
import WordingManager

public struct WordingManagerFactory {
    public init() { }

    public func produce<
        W: Wordingable,
        LM: LocalizationManager,
        WMP: WordingManagerProvider
    >(
        localizationManager: LM,
        provider: WMP
    ) -> some WordingManager {
        WordingManagerImpl<W, LM, WMP>(
            localizationManager: localizationManager,
            provider: provider
        )
    }
}
