/// MIT License
///
/// Copyright (c) 2021 Point-Free, Inc.
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.

import SwiftUI

// NB: This view works around a bug in SwiftUI's built-in view
struct _NavigationLink<Destination: View, Label: View>: View {
  @Binding var isActive: Bool
  let destination: () -> Destination
  let label: () -> Label

  @State private var isActiveState = false

  var body: some View {
    NavigationLink(
      isActive: $isActiveState,
      destination: destination,
      label: label
    )
    .bind($isActive, to: $isActiveState)
  }
}

// NB: This view modifier works around a bug in SwiftUI's built-in modifier:
// https://gist.github.com/mbrandonw/f8b94957031160336cac6898a919cbb7#file-fb11056434-md
@available(iOS 16, macOS 13, *)
struct _NavigationDestination<Destination: View>: ViewModifier {
  @Binding var isPresented: Bool
  let destination: () -> Destination

  @State private var isPresentedState = false

  func body(content: Content) -> some View {
    content
      .navigationDestination(
        isPresented: $isPresentedState,
        destination: destination
      )
      .bind($isPresented, to: $isPresentedState)
  }
}
