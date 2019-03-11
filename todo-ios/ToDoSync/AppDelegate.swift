import UIKit
import StitchCore
import StitchRemoteMongoDBService

private let todoListsDatabase = "todo"
private let todoItemsCollection = "items"

let stitch = try! Stitch.initializeAppClient(withClientAppID: "<APP_ID>")

var itemsCollection: RemoteMongoCollection<TodoItem>!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let mongoClient = try! stitch.serviceClient(fromFactory: remoteMongoClientFactory,
                                                    withName: "mongodb-atlas")

        // Set up collections
        itemsCollection = mongoClient
            .db(todoListsDatabase)
            .collection(todoItemsCollection, withCollectionType: TodoItem.self)
       
        return true
    }
}
