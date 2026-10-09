import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "pAInting"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
}
