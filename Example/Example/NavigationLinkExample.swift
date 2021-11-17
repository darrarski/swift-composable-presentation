import ComposableArchitecture
import ComposablePresentation
import SwiftUI

struct NavigationLinkExample: View {
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
  }
    .presenting(
      detailReducer,
      state: \.detail,
      action: /MasterAction.detail,
      environment: { () }
    )

  struct MasterView: View {
    let store: Store<MasterState, MasterAction>

    var body: some View {
      WithViewStore(store.stateless) { viewStore in
        NavigationLinkWithStore(
          store.scope(
            state: \.detail,
            action: MasterAction.detail
          ),
          setActive: { active in
            viewStore.send(active ? .didTapDetailButton : .didDismissDetail)
          },
          destination: DetailView.init(store:),
          label: { Text("Detail").padding() }
        )
      }
      .navigationTitle("Master")
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
        .navigationTitle("Detail")
    }
  }

  var body: some View {
    NavigationView {
      MasterView(store: Store(
        initialState: MasterState(),
        reducer: Self.masterReducer.debug(),
        environment: ()
      ))
    }
  }
}

struct NavigationLinkExample_Previews: PreviewProvider {
  static var previews: some View {
    NavigationLinkExample()
  }
}
