import Foundation

public typealias Middleware<State> = (
    @escaping (Action) -> Void,
    @escaping () -> State?,
    Action
) async -> Void

public protocol Action {}

public typealias Reducer<State> = (inout State, Action) async -> Void

public final class Store<State> {
    private var state: State
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

    public func dispatch(action: Action) async {
        // Esegui i middleware in ordine
        for middleware in middlewares {
            await middleware({ [weak self] action in
                guard let selfCopy = self else { return }
                
                Task {
                    await selfCopy.dispatch(action: action)
                }
            }, { [weak self] in self?.state }, action)
        }

        await reducer(&state, action)
    }

    public var currentState: State {
        return state
    }
}
