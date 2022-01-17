public protocol Wordingable: Codable {
    mutating func mutate(using fallback: Self)
}
