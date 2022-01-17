import Foundation
import Yams

public struct WordingDecoder<Wording: Wordingable> {
    public init() { }

    private let ymlDecoder = YAMLDecoder()

    public func decode(from data: Data) throws -> Wording {
        try ymlDecoder.decode(Wording.self, from: data)
    }
}
