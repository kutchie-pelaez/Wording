import Language
import Wording

public enum WordingEvent<Wording> where Wording: Wordingable {
    case wordingDidFetch(Localization)
    case wordingDidChange(Wording)
}
