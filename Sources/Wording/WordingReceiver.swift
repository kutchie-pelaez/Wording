public protocol WordingReceiver {
    associatedtype Wording: Wordingable

    func receive(_ wording: Wording)
}
