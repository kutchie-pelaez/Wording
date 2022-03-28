import Core
import Foundation
import Yams

public struct WordingEncoder<Wording: Wordingable> {
    public init() { }

    private let ymlEncoder = YAMLEncoder()

    public func encode(_ wording: Wording) throws -> Data {
        let ymlString = try ymlEncoder.encode(wording)

        return ymlString.data
    }
}
