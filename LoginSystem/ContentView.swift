import SwiftUI
import FirebaseCore
import FirebaseFirestore

//帳號：admin
//密碼：123456
class LoginManager: ObservableObject {
    static let shared = LoginManager()
    @Published var isLoggedIn = false
    @Published var loginError: String?
    @Published var currentUser: [String: Any]?
    private var loginInfo: [[String: Any]]?
    
    private init() {}
    
    func setLoginInfo(_ info: [[String: Any]]?) {
        self.loginInfo = info
    }
    
    func validateLogin(account: String, password: String) -> Bool {
        guard let loginInfo = loginInfo else {
            loginError = "無法取得登入資訊"
            print("LoginInfo is nil")
            return false
        }
        
        print("Attempting login with - Account: \(account), Password: \(password)")
        print("Current loginInfo: \(loginInfo)")
        
        let matchedUser = loginInfo.first { user in
            guard let storedPassword = user["password"] as? String else {
                print("Failed to get password from user data")
                return false
            }
            
            let passwordMatch = password == storedPassword
            
            print("Comparing password - Input: \(password), Stored: \(storedPassword)")
            print("Password match: \(passwordMatch)")
            
            return passwordMatch
        }
        
        if let matchedUser = matchedUser {
            isLoggedIn = true
            currentUser = matchedUser
            loginError = nil
            return true
        } else {
            loginError = "密碼錯誤"
            return false
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        fetchLoginInfo()
        return true
    }
    
    private func fetchLoginInfo() {
        let db = Firestore.firestore()
        db.collection("account").getDocuments { querySnapshot, err in
            if let err = err {
                print("Error getting documents: \(err)")
                LoginManager.shared.loginError = "無法連接到服務器"
            } else if let documents = querySnapshot?.documents, !documents.isEmpty {
                let loginInfo = documents.map { $0.data() }
                LoginManager.shared.setLoginInfo(loginInfo)
                print("登入資訊：\(loginInfo)")
            } else {
                print("No documents found in collection")
                LoginManager.shared.setLoginInfo([])
                LoginManager.shared.loginError = "無用戶資料可供驗證"
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var loginManager = LoginManager.shared
    @State private var account = ""
    @State private var password = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("管理系統")
                    .font(.largeTitle)
                if loginManager.isLoggedIn {
                    VStack {
                        Text("登入成功！")
                            .font(.title)
                            .foregroundColor(.green)
                        if let user = loginManager.currentUser {
                            Text("歡迎，\(user["account"] as? String ?? "使用者")")
                                .font(.headline)
                        }
                        Button("登出") {
                            loginManager.isLoggedIn = false
                            loginManager.currentUser = nil
                            account = ""
                            password = ""
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: 15) {
                        HStack {
                            Text("帳號：")
                            TextField("輸入帳號", text: $account)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        HStack {
                            Text("密碼：")
                            SecureField("輸入密碼", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button("登入") {
                            let success = loginManager.validateLogin(account: account, password: password)
                            if !success {
                                showingAlert = true
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("登入失敗"),
                    message: Text(loginManager.loginError ?? "未知錯誤"),
                    dismissButton: .default(Text("確定"))
                )
            }
        }
    }
}
