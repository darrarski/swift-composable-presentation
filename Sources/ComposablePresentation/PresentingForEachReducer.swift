import ComposableArchitecture
import Foundation
import CoreMedia

extension Reducer {
  /// Combines the reducer with another reducer that operates on elements of `IdentifiedArray`.
  ///
  /// - All effects returned by the element reducer will be canceled when the element's state is removed from `IdentifiedArray`.
  /// - Inspired by [Reducer.presents function](https://github.com/pointfreeco/swift-composable-architecture/blob/9ec4b71e5a84f448dedb063a21673e4696ce135f/Sources/ComposableArchitecture/Reducer.swift#L549-L572) from `iso` branch of `swift-composable-architecture` repository.
  ///
  /// - Parameters:
  ///   - toPresentationID: Transformation from `State` to unique identifier. Defaults to transformation that identifies object by type of `(State, Element)`.
  ///   - state: A key path form parent state to identified array that hold element states.
  ///   - action: A case path that can extract/embed element action from parent.
  ///   - onPresent: An action run when element is added to identified array. Defaults to empty action.
  ///   - onDismiss: An action run when element is removed from identified array. Defaults to empty action.
  ///   - element: Element reducer.
  /// - Returns: Combined reducer.
  @inlinable
  public func presentingForEach<ID, ElementState, ElementAction, Element>(
    presentationID toPresentationID: ToPresentationID<State> = .typed(Element.self),
    state toElementState: WritableKeyPath<State, IdentifiedArray<ID, ElementState>>,
    action toElementAction: CasePath<Action, (ID, ElementAction)>,
    onPresent: PresentingForEachReducerAction<ID, State, Action> = .empty,
    onDismiss: PresentingForEachReducerAction<ID, State, Action> = .empty,
    @ReducerBuilder<ElementState, ElementAction> element: () -> Element,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> _PresentingForEachReducer<Self, ID, Element>
  where ID: Hashable,
        Element: Reducer,
        Element.State == ElementState,
        Element.Action == ElementAction
  {
    .init(
      parent: self,
      toPresentationID: toPresentationID,
      toElementState: toElementState,
      toElementAction: toElementAction,
      onPresent: onPresent,
      onDismiss: onDismiss,
      element: element(),
      fileID: fileID,
      line: line
    )
  }
}

public struct _PresentingForEachReducer<
  Parent: Reducer,
  ID: Hashable,
  Element: Reducer
>: Reducer {
  @usableFromInline
  let parent: Parent

  @usableFromInline
  let toPresentationID: ToPresentationID<State>

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
  let fileID: StaticString

  @usableFromInline
  let line: UInt

  @inlinable
  init(
    parent: Parent,
    toPresentationID: ToPresentationID<State>,
    toElementState: WritableKeyPath<Parent.State, IdentifiedArray<ID, Element.State>>,
    toElementAction: CasePath<Parent.Action, (ID, Element.Action)>,
    onPresent: PresentingForEachReducerAction<ID, State, Action> = .empty,
    onDismiss: PresentingForEachReducerAction<ID, State, Action> = .empty,
    element: Element,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) {
    self.parent = parent
    self.toPresentationID = toPresentationID
    self.toElementState = toElementState
    self.toElementAction = toElementAction
    self.onPresent = onPresent
    self.onDismiss = onDismiss
    self.element = element
    self.fileID = fileID
    self.line = line
  }

  public func reduce(
    into state: inout Parent.State,
    action: Parent.Action
  ) -> Effect<Parent.Action> {
    func elementID(for action: Action) -> ID? {
      guard let (id, _) = toElementAction.extract(from: action) else {
        return nil
      }
      return id
    }

    func effectID(for id: ID) -> PresentingForEachReducerEffectID {
      .init(
        presentationID: toPresentationID(state),
        elementID: id
      )
    }

    let oldIds = state[keyPath: toElementState].ids
    let elementEffects: Effect<Action>

    if let id = elementID(for: action) {
      elementEffects = EmptyReducer()
        .forEach(
          toElementState,
          action: toElementAction,
          element: { element },
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
    var presentationEffects: [Effect<Action>] = []

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
  public typealias Run = (ID, inout State) -> Effect<Action>

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
  let presentationID: AnyHashable

  @usableFromInline
  let elementID: AnyHashable

  @inlinable
  init(presentationID: AnyHashable, elementID: AnyHashable) {
    self.presentationID = presentationID
    self.elementID = elementID
  }
}
