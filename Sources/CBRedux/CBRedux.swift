import Foundation

public final class Store<S: State>: ObservableObject {
    @Published public private(set) var state: S
    
    private var reducer: Reducer
    private var middlewares: [Middleware]
    
    public init(
        initialState: S,
        reducer: Reducer,
        middlewares: [Middleware] = []
    ) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares
    }
    
    @MainActor
    public func dispatch(action: Action) async throws {
        state = reducer.reduce(oldState: state, with: action) as! S
        
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
