import ComposableArchitecture
import Foundation
import CoreMedia

extension ReducerProtocol {
  /// Combines the reducer with another reducer that operates on elements of `IdentifiedArray`.
  ///
  /// - All effects returned by the element reducer will be canceled when the element's state is removed from `IdentifiedArray`.
  /// - Inspired by [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
  ///
  /// - Parameters:
  ///   - reducerID: Unique identifier for the presentation. Defaults to new UUID.
  ///   - state: A key path form parent state to identified array that hold element states.
  ///   - action: A case path that can extract/embed element action from parent.
  ///   - onPresent: An action run when element is added to identified array. Defaults to empty action.
  ///   - onDismiss: An action run when element is removed from identified array. Defaults to empty action.
  ///   - element: Element reducer.
  /// - Returns: Combined reducer.
  @inlinable
  public func presentingForEach<ID: Hashable, Element: ReducerProtocol>(
    reducerID: UUID = UUID(),
    state toElementState: WritableKeyPath<State, IdentifiedArray<ID, Element.State>>,
    action toElementAction: CasePath<Action, (ID, Element.Action)>,
    onPresent: PresentingForEachReducerAction<ID, State, Action> = .empty,
    onDismiss: PresentingForEachReducerAction<ID, State, Action> = .empty,
    @ReducerBuilderOf<Element> element: () -> Element,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> _PresentingForEachReducer<Self, ID, Element> {
    .init(
      reducerID: reducerID,
      parent: self,
      toElementState: toElementState,
      toElementAction: toElementAction,
      onPresent: onPresent,
      onDismiss: onDismiss,
      element: element(),
      file: file,
      fileID: fileID,
      line: line
    )
  }
}

public struct _PresentingForEachReducer<
  Parent: ReducerProtocol,
  ID: Hashable,
  Element: ReducerProtocol
>: ReducerProtocol {
  @usableFromInline
  let reducerID: UUID

  @usableFromInline
  let parent: Parent

  @usableFromInline
  let toElementState: WritableKeyPath<Parent.State, IdentifiedArray<ID, Element.State>>

  @usableFromInline
  let toElementAction: CasePath<Parent.Action, (ID, Element.Action)>

  @usableFromInline
  let onPresent: PresentingForEachReducerAction<ID, State, Action>

  @usableFromInline
  let onDismiss: PresentingForEachReducerAction<ID, State, Action>

  @usableFromInline
  let element: Element

  @usableFromInline
  let file: StaticString

  @usableFromInline
  let fileID: StaticString

  @usableFromInline
  let line: UInt

  @inlinable
  init(
    reducerID: UUID,
    parent: Parent,
    toElementState: WritableKeyPath<Parent.State, IdentifiedArray<ID, Element.State>>,
    toElementAction: CasePath<Parent.Action, (ID, Element.Action)>,
    onPresent: PresentingForEachReducerAction<ID, State, Action> = .empty,
    onDismiss: PresentingForEachReducerAction<ID, State, Action> = .empty,
    element: Element,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) {
    self.reducerID = reducerID
    self.parent = parent
    self.toElementState = toElementState
    self.toElementAction = toElementAction
    self.onPresent = onPresent
    self.onDismiss = onDismiss
    self.element = element
    self.file = file
    self.fileID = fileID
    self.line = line
  }

  public func reduce(
    into state: inout Parent.State,
    action: Parent.Action
  ) -> Effect<Parent.Action, Never> {
    func elementID(for action: Action) -> ID? {
      guard let (id, _) = toElementAction.extract(from: action) else {
        return nil
      }
      return id
    }

    func effectID(for id: ID) -> PresentingForEachReducerEffectID {
      .init(reducerID: reducerID, elementID: id)
    }

    let oldIds = state[keyPath: toElementState].ids
    let elementEffects: Effect<Action, Never>

    if let id = elementID(for: action) {
      elementEffects = EmptyReducer()
        .forEach(
          toElementState,
          action: toElementAction,
          { element },
          file: file,
          fileID: fileID,
          line: line
        )
        .reduce(into: &state, action: action)
        .cancellable(id: effectID(for: id))
    } else {
      elementEffects = .none
    }

    let parentEffects = parent.reduce(into: &state, action: action)
    let newIds = state[keyPath: toElementState].ids
    let presentedIds = newIds.subtracting(oldIds)
    let dismissedIds = oldIds.subtracting(newIds)
    var presentationEffects: [Effect<Action, Never>] = []

    dismissedIds.forEach { id in
      presentationEffects.append(onDismiss.run(id, &state))
      presentationEffects.append(.cancel(id: effectID(for: id)))
    }

    presentedIds.forEach { id in
      presentationEffects.append(onPresent.run(id, &state))
    }

    return .merge(
      elementEffects,
      parentEffects,
      .merge(presentationEffects)
    )
  }
}

/// Describes for-each presentation action, like `onPresent` or `onDismiss`.
public struct PresentingForEachReducerAction<ID, State, Action> {
  public typealias Run = (ID, inout State) -> Effect<Action, Never>

  /// An action that performs no state mutations and returns no effects.
  public static var empty: Self { .init { _, _ in .none } }

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run
}

/// Effect produced by element reducer within `.presentingForEach` higher order reducer.
public struct PresentingForEachReducerEffectID: Hashable {
  @usableFromInline
  let reducerID: UUID

  @usableFromInline
  let elementID: AnyHashable

  @inlinable
  init(reducerID: UUID, elementID: AnyHashable) {
    self.reducerID = reducerID
    self.elementID = elementID
  }
}
