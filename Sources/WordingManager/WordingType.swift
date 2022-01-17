enum WordingType:
    String,
    CustomStringConvertible
{

    case bundled
    case persisted

    // MARK: - CustomStringConvertible

    var description: String {
        rawValue
    }
}
