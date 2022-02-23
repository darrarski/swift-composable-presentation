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
            SheetExample()

          case .fullScreenCoverExample:
            FullScreenCoverExample()

          case .navigationLinkExample:
            NavigationLinkExample()

          case .navigationLinkSelectionExample:
            NavigationLinkSelectionExample()

          case .forEachStoreExample:
            ForEachStoreExample()

          case .popToRootExample:
            PopToRootExample()

          case .switchStoreExample:
            SwitchStoreExample()
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
