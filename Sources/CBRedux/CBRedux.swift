import Foundation

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
