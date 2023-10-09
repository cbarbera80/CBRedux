import Foundation

public struct AnyMiddleware<State>: MiddlewareProtocol {
    private let _process: (State, Action) async throws -> Action?

    public init<M: MiddlewareProtocol>(_ middleware: M) where M.StateType == State {
        self._process = middleware.process
    }

    public func process(state: State, with action: Action) async throws -> Action? {
        return try await _process(state, action)
    }
}
