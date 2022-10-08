import Foundation
import Yams

enum WordingGenerationError: Error {
    case invaidYMLString
    case emptyYML
}

let arguments = ProcessInfo.processInfo.arguments

guard arguments.count > 2 else {
    print("Expected input and output in arguments")
    exit(1)
}

let inputURL = URL(fileURLWithPath: arguments[1])
let outputURL =  URL(fileURLWithPath: arguments[2])
let fileManager = FileManager.default

var rootConfigNode: Node {
    get throws {
        let data = try Data(contentsOf: inputURL)

        guard let ymlString = String(
            data: data,
            encoding: .utf8
        ) else {
            throw WordingGenerationError.invaidYMLString
        }

        let parser = try Parser(yaml: ymlString)

        guard let rootNode = try parser.nextRoot() else {
            throw WordingGenerationError.emptyYML
        }

        return rootNode
    }
}

func createOutputFileIfNeeded() throws {
    try "".write(to: outputURL, atomically: true, encoding: .utf8)
}

func appendWordingString(_ string: String) throws {
    let currentData = try Data(contentsOf: outputURL)

    guard let currentString = String(
        data: currentData,
        encoding: .utf8
    ) else {
        throw WordingGenerationError.invaidYMLString
    }

    try (currentString + string).write(to: outputURL, atomically: true, encoding: .utf8)
}

private func writeImportStatements() throws {
    try appendWordingString(
            """
            import Wording
            """.newLined(2)
    )
}

private func writeMainBody() throws {
    try appendWordingString(
            """
            public enum Wording: Wordingable {
                fileprivate static var wording = [String: String]()

                public static func complement(using wording: [String: Any]) {
                    complement(using: wording, path: nil)
                }

                private static func complement(using wording: [String: Any], path: String?) {
                    for (key, value) in wording {
                        let path = [path, key]
                            .compactMap { $0}
                            .joined(separator: ".")

                        if let leaf = value as? String {
                            Self.wording[path] = leaf
                        } else if let node = value as? [String: Any] {
                            complement(using: node, path: path)
                        }
                    }
                }
            }
            """.newLined(2)
    )
}

private func writeWordingNode(
    _ node: Node,
    nodeKey: String? = nil,
    chain: [String] = [],
    isRoot: Bool = false,
    addAdditionalNewLine: Bool = false,
    indentation: Int = 0
) throws {
    switch node {
    case let .scalar(scalar):
        guard let nodeKey, scalar.style == .plain else { break }

        let propertyChain = chain.joined(separator: ".")

        try appendWordingString(
                """
                public static var \(nodeKey.lowercasingFirstLetter()): String { leaf("\(propertyChain)") }
                """.indented(indentation).newLined(addAdditionalNewLine ? 2 : 1)
        )

    case let .mapping(mapping):
        let keys = mapping.keys.map { String($0.string ?? "") }

        if isRoot {
            try appendWordingString(
                    """
                    extension Wording {
                    """.indented(indentation).newLined(1)
            )
        } else {
            guard let nodeKey else { return }

            try appendWordingString(
                    """
                    public enum \(nodeKey.capitalizingFirstLetter()) {
                    """.indented(indentation).newLined(1)
            )
        }

        for (index, node) in mapping.values.enumerated() {
            let key = keys[index]
            var addAdditionalNewLine = mapping.count - 1 != index

            if index < mapping.values.count - 1 {
                let nexValue = mapping.values[index + 1]

                if
                    case .scalar(let currentScalar) = node,
                    case .scalar(let nextScalar) = nexValue,
                    currentScalar.style == .plain,
                    nextScalar.style == .plain
                {
                    addAdditionalNewLine = false
                }
            }

            try writeWordingNode(
                node,
                nodeKey: key,
                chain: chain + [key],
                addAdditionalNewLine: addAdditionalNewLine,
                indentation: indentation + 1
            )
        }

        try appendWordingString(
                """
                }
                """.indented(indentation).newLined(addAdditionalNewLine ? 2 : 1)
        )

    default:
        break
    }
}

private func writeNewLine() throws {
    try appendWordingString("\n")
}

private func writeLeafFunction() throws {
    try appendWordingString(
            #"""
            private func leaf(_ path: String) -> String {
                guard let leafValue = Wording.wording[path] else {
                    assertionFailure("No wording value for \(path)")
                    return ""
                }

                return leafValue
            }
            """#.newLined(1)
    )
}

try createOutputFileIfNeeded()
try writeImportStatements()
try writeMainBody()
try writeWordingNode(try rootConfigNode, isRoot: true)
try writeNewLine()
try writeLeafFunction()

extension String {
    fileprivate func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }

    fileprivate func lowercasingFirstLetter() -> String {
        prefix(1).lowercased() + dropFirst()
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
