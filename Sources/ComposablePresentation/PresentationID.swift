/// `State` → presentation identifier transformation for `.presenting` higher order reducers.
public struct ToPresentationID<State> {
  public typealias Run = (State) -> AnyHashable

  /// Identifier presentation with the provided static identifier.
  ///
  /// - Parameter id: Unique identifier
  /// - Returns: Transformation.
  public static func `static`(_ id: AnyHashable) -> ToPresentationID<State> {
    .init { _ in id }
  }

  /// Identifies presentation by type of `State`
  ///
  /// - Returns: Transformation.
  public static func typeId() -> ToPresentationID<State> {
    .init { ObjectIdentifier(type(of: $0)) }
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
