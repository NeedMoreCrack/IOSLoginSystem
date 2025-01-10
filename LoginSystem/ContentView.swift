import SwiftUI

struct ContentView: View {
    @State private var account = ""
    @State private var password = ""
    var body: some View {
        VStack {
            HStack {
                Text("帳號：")
                TextField("輸入帳號：",text: $account)
                    .background(Color.white)
            }
            HStack {
                Text("密碼：")
                SecureField("輸入密碼：",text: $password)
                    .background(Color.white)
            }
        }
        .padding()
        .background(Color.green)
    }
}

#Preview {
    ContentView()
}
