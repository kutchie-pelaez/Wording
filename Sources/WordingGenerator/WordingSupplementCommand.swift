import Foundation
import PathKit
import SwiftCLI
import Yams

enum WordingSupplementCommandError: Error {
    case invaidYMLString
    case emptyYML
    case invalidNode
}

final class WordingSupplementCommand: Command {

    @Param var supplementer: String

    @Param var supplementee: String

    // MARK: -

    private var supplementerPath: Path {
        Path(supplementer)
    }

    private var supplementeePath: Path {
        Path(supplementee)
    }

    private func rootNode(at path: Path) throws -> Node {
        let data = try path.read()

        guard let ymlString = String(
            data: data,
            encoding: .utf8
        ) else {
            throw WordingSupplementCommandError.invaidYMLString
        }

        let parser = try Parser(yaml: ymlString)

        guard let rootNode = try parser.nextRoot() else {
            throw WordingSupplementCommandError.emptyYML
        }

        return rootNode
    }

    @discardableResult
    private func writeSorted(
        _ node: Node,
        to path: Path
    ) throws -> Node {
        let ymlString = try serialize(
            node: node,
            allowUnicode: true,
            sortKeys: true
        )

        guard let ymlData = ymlString.data(using: .utf8) else {
            throw WordingSupplementCommandError.invaidYMLString
        }

        try path.write(ymlData)

        return try rootNode(at: path)
    }

    private func supplement(
        _ supplementee: inout Node,
        with supplementer: Node
    ) throws {
        var supplementeePairs = [[String]: Node]()
        traverse(supplementee) { chain, value in
            supplementeePairs[chain] = value
        }

        var supplementerPairs = [[String]: Node]()
        traverse(supplementer) { chain, value in
            supplementerPairs[chain] = value
        }

        var pairsToSupplement = [[String]: Node]()
        for supplementerPair in supplementerPairs {
            if
                let supplementeeValue = supplementeePairs[supplementerPair.key],
                supplementeeValue.mapping == nil
            {
                pairsToSupplement[supplementerPair.key] = supplementeeValue
            }
        }

        var nulledSupplementer = try nulledNode(supplementer)

        for pairToSupplement in pairsToSupplement {
            setNodeValue(
                pairToSupplement.value,
                for: &nulledSupplementer,
                at: pairToSupplement.key
            )
        }

        supplementee = nulledSupplementer
    }

    private func setNodeValue(
        _ value: Node,
        for node: inout Node,
        previousChain: [String] = [],
        at chain: [String]
    ) {
        switch node {
        case .scalar:
            guard previousChain == chain else { break }

            node = value

        case let .mapping(mapping):
            var newMapping = mapping
            for (mappingKey, mappingValue) in mapping {
                var mappingValue = mappingValue
                setNodeValue(
                    value,
                    for: &mappingValue,
                    previousChain: previousChain + [mappingKey.string ?? ""],
                    at: chain
                )
                newMapping[mappingKey] = mappingValue
            }
            node = .mapping(newMapping)

        case .sequence:
            fatalError()
        }
    }

    private func traverse(
        _ node: Node,
        chain: [String] = [],
        block: ([String], Node) -> Void
    ) {
        guard let mapping = node.mapping else { return }

        for (key, value) in mapping {
            guard let string = key.string else { continue }

            let newChain = chain + [string]
            block(newChain, value)

            traverse(
                value,
                chain: newChain,
                block: block
            )
        }
    }

    private func nulledNode(_ node: Node) throws -> Node {
        switch node {
        case .scalar:
            return Node(
                "null",
                Tag(.null)
            )

        case let .mapping(mapping):
            var pairs = [(Node, Node)]()

            for (key, value) in mapping {
                let valueSupplement = try nulledNode(value)
                pairs.append((key, valueSupplement))
            }

            return .mapping(Node.Mapping(pairs))

        case .sequence:
            throw WordingSupplementCommandError.invalidNode
        }
    }

    // MARK: - Routable

    var name: String {
        "supplement"
    }

    var shortDescription: String {
        "Supplement wording.yml config with nulls for missing fields base on provided config"
    }

    // MARK: - Command

    func execute() throws {
        var supplementer = try rootNode(at: supplementerPath)
        var supplementee = try rootNode(at: supplementeePath)

        supplementer = try writeSorted(
            supplementer,
            to: supplementerPath
        )
        supplementee = try writeSorted(
            supplementee,
            to: supplementeePath
        )

        try supplement(
            &supplementee,
            with: supplementer
        )

        try writeSorted(
            supplementee,
            to: supplementeePath
        )
    }
}
