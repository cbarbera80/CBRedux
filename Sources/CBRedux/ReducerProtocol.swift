import Foundation

public protocol Reducer {
    func reduce(oldState: State, with action: Action) -> State
}
