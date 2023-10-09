import Foundation

public final class Store<R: Reducer>: ObservableObject {
    @Published public private(set) var state: State
    
    private var reducer: R
    private var middlewares: [Middleware]
    
    public init(
        initialState: State,
        reducer: R,
        middlewares: [Middleware] = []
    ) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares
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
