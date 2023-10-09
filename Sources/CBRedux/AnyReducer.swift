import Foundation

public struct AnyReducer<State>: ReducerProtocol {
    private let _reduce: (State, Action) -> State

    public init<R: ReducerProtocol>(_ reducer: R) where R.StateType == State {
        self._reduce = reducer.reduce
    }

    public func reduce(oldState: State, with action: Action) -> State {
        return _reduce(oldState, action)
    }
}
