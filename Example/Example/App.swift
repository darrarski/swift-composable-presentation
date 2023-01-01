import ComposableArchitecture
import SwiftUI

@main
struct App: SwiftUI.App {
  var body: some Scene {
    WindowGroup {
      AppView()
    }
  }
}

struct AppView: View {
  enum Destination: String, CaseIterable {
    case sheetExample
    case fullScreenCoverExample
    case navigationLinkExample
    case navigationLinkSelectionExample
    case forEachStoreExample
    case popToRootExample
    case switchStoreExample
    case destinationExample

    var title: String {
      rawValue[rawValue.startIndex].uppercased() +
      rawValue[rawValue.index(after: rawValue.startIndex)...]
    }
  }

  @State var destination: Destination?

  var body: some View {
    if let destination = destination {
      VStack(spacing: 0) {
        ZStack {
          switch destination {
          case .sheetExample:
            SheetExampleView(store: Store(
              initialState: SheetExample.State(),
              reducer: SheetExample()._printChanges()
            ))

          case .fullScreenCoverExample:
            FullScreenCoverExampleView(store: Store(
              initialState: FullScreenCoverExample.State(),
              reducer: FullScreenCoverExample()._printChanges()
            ))

          case .navigationLinkExample:
            NavigationLinkExampleView(store: Store(
              initialState: NavigationLinkExample.State(),
              reducer: NavigationLinkExample()._printChanges()
            ))

          case .navigationLinkSelectionExample:
            NavigationLinkSelectionExampleView(store: Store(
              initialState: NavigationLinkSelectionExample.State(),
              reducer: NavigationLinkSelectionExample()._printChanges()
            ))

          case .forEachStoreExample:
            ForEachStoreExampleView(store: Store(
              initialState: ForEachStoreExample.State(),
              reducer: ForEachStoreExample()._printChanges()
            ))

          case .popToRootExample:
            PopToRootExampleView(store: Store(
              initialState: PopToRootExample.State(),
              reducer: PopToRootExample()._printChanges()
            ))

          case .switchStoreExample:
            SwitchStoreExampleView(store: Store(
              initialState: SwitchStoreExample.State(),
              reducer: SwitchStoreExample()._printChanges()
            ))

          case .destinationExample:
            DestinationExampleView(store: Store(
              initialState: DestinationExample.State(),
              reducer: DestinationExample()._printChanges()
            ))
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        Divider()

        Button(action: { self.destination = nil }) {
          Text("Quit example").padding()
        }
      }
    } else {
      List {
        Section {
          ForEach(Destination.allCases, id: \.self) { destination in
            Button(action: { self.destination = destination }) {
              Text(destination.title)
            }
          }
        } header: {
          Text("Examples")
        }
      }
    }
  }
}

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    AppView()
  }
}
