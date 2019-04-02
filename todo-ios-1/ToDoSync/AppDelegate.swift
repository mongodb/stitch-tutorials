import UIKit
import StitchCore
import StitchRemoteMongoDBService

private let todoListsDatabase = "todo"
private let todoItemsCollection = "items"

// TODO:
// 1.
// let stitch = try! Stitch.initializeAppClient(withClientAppID: "<APP_ID>")

var itemsCollection: RemoteMongoCollection<TodoItem>!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // TODO:
        // 2. Instantiate a RemoteMongoClient
        // let mongoClient =

        // 3. Set up the items collection
        // itemsCollection = 
       
        return true
    }
}
