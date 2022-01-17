public protocol WordingReceiver {
    associatedtype Wording

    func receive(_ wording: Wording)
}
