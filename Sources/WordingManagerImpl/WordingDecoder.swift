import CoreUtils
import Foundation
import Yams

struct WordingDecoder {
    private let ymlDecoder = YAMLDecoder()

    func decode(from data: Data) throws -> [String: Any] {
        guard
            let yaml = String(data: data, encoding: .utf8),
            let wording = try load(yaml: yaml) as? [String: Any]
        else {
            throw ContextError(message: "Failed to load YAML")
        }

        return wording
    }
}
