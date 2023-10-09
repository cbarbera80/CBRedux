import Foundation

public protocol MiddlewareProtocol {
    associatedtype StateType
    func process(state: StateType, with action: Action) async throws -> Action?
}
