import Foundation

public protocol ReducerProtocol {
    associatedtype StateType
    func reduce(oldState: StateType, with action: Action) -> StateType
}
