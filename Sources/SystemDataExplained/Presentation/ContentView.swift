import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        CockpitView(model: model)
    }
}
