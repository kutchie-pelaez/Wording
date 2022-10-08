import LocalizationManager
import Wording
import WordingManager

public struct WordingManagerFactory {
    public static func produce(
        wordingType: (some Wordingable).Type,
        localizationManager: some LocalizationManager,
        provider: some WordingManagerProvider
    ) -> some WordingManager {
        WordingManagerImpl(
            wordingType: wordingType,
            localizationManager: localizationManager,
            provider: provider
        )
    }
}
