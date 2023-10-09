import Foundation

public protocol Middleware {
    func process(state: State, with action: Action) async throws -> Action?
}
