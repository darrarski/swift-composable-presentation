/// `State` → presentation identifier transformation for `.presenting` higher order reducers.
public struct ToPresentationID<State> {
  public typealias Run = (State) -> AnyHashable

  /// Identifier presentation with the provided static identifier.
  ///
  /// - Parameter id: Unique identifier
  /// - Returns: Transformation.
  public static func value(_ id: AnyHashable) -> ToPresentationID<State> {
    .init { _ in id }
  }

  /// Identifies presentation by type of `(State, Presented)`
  ///
  /// - Returns: Transformation.
  public static func typed<Presented>(_ presentedType: Presented.Type) -> ToPresentationID<State> {
    .init { _ in ObjectIdentifier(type(of: (State.self, presentedType))) }
  }

  /// Identifies presentation with value of `State` at provided key path.
  ///
  /// - Parameter keyPath: The key path for unique presentation identifier.
  /// - Returns: Transformation.
  public static func keyPath(
    _ keyPath: KeyPath<State?, AnyHashable>
  ) -> ToPresentationID<State> {
    .init { $0[keyPath: keyPath] }
  }

  public init(run: @escaping Run) {
    self.run = run
  }

  public var run: Run

  public func callAsFunction(_ state: State) -> AnyHashable {
    run(state)
  }
}
