import Foundation
import OSLog

public enum KiteLog {
    public static let app = Logger(subsystem: "com.chase.kite", category: "app")
    public static let sync = Logger(subsystem: "com.chase.kite", category: "sync")
    public static let canvas = Logger(subsystem: "com.chase.kite", category: "canvas")
    public static let ai = Logger(subsystem: "com.chase.kite", category: "ai")
}
