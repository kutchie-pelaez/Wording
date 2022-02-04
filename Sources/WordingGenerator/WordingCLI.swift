import Foundation
import SwiftCLI

final class WordingCLI {
    private lazy var cli: CLI = {
        let cli = CLI(
            name: "wording",
            version: "1.0.0",
            commands: [
                WordingGenCommand(),
                WordingSupplementCommand(),
            ]
        )

        cli.helpCommand = nil

        return cli
    }()

    func execute(arguments: [String]? = nil) {
        let status: Int32

        if let arguments = arguments {
            status = cli.go(with: arguments)
        } else {
            status = cli.go()
        }

        exit(status)
    }
}
