import ComposableArchitecture

extension Reducer {
  public func presenting<LocalState, LocalAction, LocalEnvironment>(
    forEach localReducer: Reducer<LocalState, LocalAction, LocalEnvironment>,
    breakpointOnNil: Bool = true,
    state toLocalState: WritableKeyPath<State, IdentifiedArrayOf<LocalState>>,
    action toLocalAction: CasePath<Action, (LocalState.ID, LocalAction)>,
    environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
    onRun: @escaping (LocalState.ID) -> Void = { _ in },
    onCancel: @escaping (LocalState.ID) -> Void = { _ in }
  ) -> Self {
    let presentationId = UUID()
    return Reducer { state, action, environment in
      let oldIds = state[keyPath: toLocalState].ids
      let localEffects: Effect<Action, Never>

      if let (id, _) = toLocalAction.extract(from: action) {
        onRun(id)
        localEffects = localReducer
          .forEach(
            state: toLocalState,
            action: toLocalAction,
            environment: toLocalEnvironment,
            breakpointOnNil: breakpointOnNil
          )
          .run(&state, action, environment)
          .cancellable(id: CancellationId(
            presentationId: presentationId,
            elementId: id
          ))
      } else {
        localEffects = .none
      }

      let effects = run(&state, action, environment)
      var cancellationEffects: [Effect<Action, Never>] = []
      let newIds = state[keyPath: toLocalState].ids
      let removedIds = oldIds.subtracting(newIds)

      removedIds.forEach { id in
        onCancel(id)
        cancellationEffects.append(.cancel(id: CancellationId(
          presentationId: presentationId,
          elementId: id
        )))
      }

      return .merge(
        localEffects,
        effects,
        .merge(cancellationEffects)
      )
    }
  }
}

private struct CancellationId: Hashable {
  var presentationId: UUID
  var elementId: AnyHashable
}
