import Foundation

public protocol Action {}

public protocol ReducerProtocol {
    associatedtype StateType
    func reduce(oldState: StateType, with action: Action) -> StateType
}

public protocol MiddlewareProtocol {
    associatedtype StateType
    func process(state: StateType, with action: Action) async throws -> Action?
}

public struct AnyReducer<State>: ReducerProtocol {
    private let _reduce: (State, Action) -> State

    public init<R: ReducerProtocol>(_ reducer: R) where R.StateType == State {
        self._reduce = reducer.reduce
    }

    public func reduce(oldState: State, with action: Action) -> State {
        return _reduce(oldState, action)
    }
}

public struct AnyMiddleware<State>: MiddlewareProtocol {
    private let _process: (State, Action) async throws -> Action?

    public init<M: MiddlewareProtocol>(_ middleware: M) where M.StateType == State {
        self._process = middleware.process
    }

    public func process(state: State, with action: Action) async throws -> Action? {
        return try await _process(state, action)
    }
}

public final class Store<State>: ObservableObject {
    @Published public private(set) var state: State
    private var reducer: AnyReducer<State>
    private var middlewares: [AnyMiddleware<State>]
    
    
    public init<R: ReducerProtocol, M: MiddlewareProtocol>(
        initialState: State,
        reducer: R,
        middlewares: [M] = []
    ) where R.StateType == State, M.StateType == State {
        self.state = initialState
        self.reducer = AnyReducer(reducer)
        self.middlewares = middlewares.map(AnyMiddleware.init)
    }
    
    @MainActor
    public func dispatch(action: Action) async throws {
        state = reducer.reduce(oldState: state, with: action)
        
        try await withThrowingTaskGroup(of: Action?.self) { group in
            for middleware in middlewares {
                _ = group.addTaskUnlessCancelled {
                    try await middleware.process(state: self.state, with: action)
                }
            }
            
            for try await case let nextAction? in group where !Task.isCancelled {
                try await dispatch(action: nextAction)
            }
        }
    }
}
