import Foundation
import PathKit
import SwiftCLI
import Yams

private let executableParentPath = Path(ProcessInfo.processInfo.arguments[0]).parent()

enum WordingGenCommandError: Error {
    case invaidYMLString
    case emptyYML
}

final class WordingGenCommand: Command {

    @Param var input: String

    @Param var output: String

    @Param var structName: String?

    // MARK: -

    private var inputPath: Path {
        executableParentPath + input
    }

    private var outputPath: Path {
        executableParentPath + output
    }

    private var computedStructName: String {
        structName ?? output.replacingOccurrences(of: ".swift", with: "")
    }

    private func rootConfigNode(at path: String) throws -> Node {
        let data = try inputPath.read()

        guard let ymlString = String(
            data: data,
            encoding: .utf8
        ) else {
            throw WordingGenCommandError.invaidYMLString
        }

        let parser = try Parser(yaml: ymlString)

        guard let rootNode = try parser.nextRoot() else {
            throw WordingGenCommandError.emptyYML
        }

        return rootNode
    }

    private func createOutputFileIfNeeded() throws {
        try outputPath.write("")
    }

    private func appendWordingString(_ string: String) throws {
        let currentData = try outputPath.read()

        guard let currentString = String(
            data: currentData,
            encoding: .utf8
        ) else {
            throw WordingGenCommandError.invaidYMLString
        }

        try outputPath.write(currentString + string)
    }

    private func writeHeader() throws {
        try outputPath.write(
            """
            import Wording

            public struct \(computedStructName): Wordingable {
            """.newLined(1)
        )
    }

    private func writeWordingNode(
        _ node: Node,
        indentation: Int = 1
    ) throws {
        switch node {
        case let .scalar(scalar):
            guard scalar.style == .plain else {
                break
            }

        case let .mapping(mapping):
            let keys = mapping.keys
                .map { String($0.string ?? "") }

            try appendWordingString(
                """
                private enum CodingKeys: String, CodingKey {
                    case \(keys.map { "_\($0) = \"\($0)\"" }.joined(separator: ", "))
                }
                """.indented(indentation).newLined(2)
            )

            for (index, key) in keys.enumerated() {
                let value = mapping.values[index]
                let type: String
                if value.scalar?.style == .plain {
                    type = "String"
                } else {
                    type = key.capitalizingFirstLetter()
                }

                try appendWordingString(
                    """
                    public var \(key): \(type) { _\(key)! }
                    fileprivate var _\(key): \(type)?
                    """.indented(indentation).newLined(index == keys.count - 1 ? 1 : 2)
                )
            }

            for (index, value) in mapping.values.enumerated() {
                guard value.scalar?.style != .plain else { continue }

                let key = mapping.keys[index]

                try appendWordingString("\n")
                
                try appendWordingString(
                    """
                    public struct \(key.string?.capitalized ?? ""): Codable {
                    """.indented(indentation).newLined(1)
                )

                try writeWordingNode(
                    value,
                    indentation: indentation + 1
                )

                try appendWordingString(
                    """
                    }
                    """.indented(indentation).newLined(1)
                )
            }

        default:
            break
        }
    }

    private func writeWordingableConformance() throws {
        let root = try rootConfigNode(at: input)
        var body: String = ""
        traverseNode(root) { chain in
            let chainString = chain.map { "_\($0)" }.joined(separator: "?.")
            let bodyLine = "if \(chainString) == nil { \(chainString) = fallback.\(chainString) }".indented(1)
            body.append(bodyLine)
            body.append("\n")
        }
        body.removeLast()

        try appendWordingString("\n")

        try appendWordingString(
            """
            // MARK: - Wordingable
            """.indented(1).newLined(2)
        )

        try appendWordingString(
            """
            public mutating func mutate(using fallback: \(computedStructName)) {
            \(body)
            }
            """.indented(1).newLined(1)
        )
    }

    private func traverseNode(
        _ node: Node,
        chain: [String] = [],
        chainBlock: ([String]) -> Void
    ) {
        guard let mapping = node.mapping else { return }

        for (index, key) in mapping.keys.enumerated() {
            let value = mapping.values[index]

            guard let string = key.string else { continue }

            let newChain = chain + [string]
            chainBlock(newChain)

            traverseNode(
                value,
                chain: newChain,
                chainBlock: chainBlock
            )
        }

    }

    // MARK: - Routable

    var name: String {
        "generate"
    }

    var shortDescription: String {
        "Generates Wording.swift file based on provided wording.yml config"
    }

    // MARK: - Command

    func execute() throws {
        let root = try rootConfigNode(at: input)

        try createOutputFileIfNeeded()
        try writeHeader()
        try writeWordingNode(root)
        try writeWordingableConformance()
        try appendWordingString("}".newLined(1))
    }
}

extension String {
    fileprivate func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }

    fileprivate func indented(_ count: Int) -> String {
        split(separator: "\n")
            .map { Array(repeating: "    ", count: count).joined() + $0 }
            .joined(separator: "\n")
    }

    fileprivate func newLined(_ count: Int) -> String {
        self + Array(repeating: "\n", count: count)
            .joined()
    }
}
