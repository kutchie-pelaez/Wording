import Core
import Wording

public protocol WordingManager {
    associatedtype WordingType: Wordingable

    var wordingSubject: ValueSubject<WordingType> { get }
}
