import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct SheetExample: View {
  struct MasterState {
    var detail: DetailState?
  }

  enum MasterAction {
    case didTapDetailButton
    case didDismissDetail
    case detail(DetailAction)
  }

  static let masterReducer = Reducer<MasterState, MasterAction, Void> { state, action, _ in
    switch action {
    case .didTapDetailButton:
      state.detail = DetailState()
      return .none

    case .didDismissDetail:
      state.detail = nil
      return .none

    case .detail(_):
      return .none
    }
  }.presenting(
    detailReducer,
    state: \.detail,
    action: /MasterAction.detail,
    environment: { () }
  )

  struct MasterView: View {
    let store: Store<MasterState, MasterAction>

    var body: some View {
      WithViewStore(store.stateless) { viewStore in
        Button(action: { viewStore.send(.didTapDetailButton) }) {
          Text("Detail")
        }
        .sheet(
          store.scope(
            state: \.detail,
            action: MasterAction.detail
          ),
          onDismiss: { viewStore.send(.didDismissDetail) },
          content: DetailView.init(store:)
        )
      }
    }
  }

  struct DetailState {
    var timer = TimerState()
  }

  enum DetailAction {
    case timer(TimerAction)
  }

  static let detailReducer = Reducer<DetailState, DetailAction, Void>.combine(
    timerReducer.pullback(
      state: \.timer,
      action: /DetailAction.timer,
      environment: { () }
    )
  )

  struct DetailView: View {
    let store: Store<DetailState, DetailAction>

    var body: some View {
      TimerView(store: store.scope(
        state: \.timer,
        action: DetailAction.timer
      ))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
    }
  }

  var body: some View {
    MasterView(store: Store(
      initialState: MasterState(),
      reducer: Self.masterReducer.debug(),
      environment: ()
    ))
  }
}

struct SheetExample_Previews: PreviewProvider {
  static var previews: some View {
    SheetExample()
  }
}
