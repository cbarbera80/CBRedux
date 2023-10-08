import Foundation

public typealias Middleware<State> = (_ state: State, _ action: Action) async throws -> Action?

public protocol Action {}

public typealias Reducer<State> = (_ oldState: State, _ with: Action) -> State

@MainActor
public final class Store<State>: ObservableObject {
    @Published public private(set) var state: State
    private var reducer: Reducer<State>
    private var middlewares: [Middleware<State>]

    public init(
        initialState: State,
        reducer: @escaping Reducer<State>,
        middlewares: [Middleware<State>] = []
    ) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares
    }

    @MainActor
    public func dispatch(action: Action) async throws {
        state = reducer(state, action)

        try await withThrowingTaskGroup(of: Action?.self) { group in
            middlewares.forEach { middleware in
                _ = group.addTaskUnlessCancelled {
                    try await middleware(self.state, action)
                }
            }

            for try await case let nextAction? in group where !Task.isCancelled {
                try await dispatch(action: nextAction)
            }
        }
    }
}
