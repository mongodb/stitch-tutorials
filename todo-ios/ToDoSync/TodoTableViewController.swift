import UIKit
@testable import StitchCoreRemoteMongoDBService
@testable import StitchRemoteMongoDBService
@testable import StitchCore
@testable import StitchCoreSDK
import MongoSwift
import Toast_Swift
import BEMCheckBox

private var toastStyle: ToastStyle {
    var toastStyle = ToastStyle()
    toastStyle.messageFont = .systemFont(ofSize: 10.0)
    return toastStyle
}

private class ItemsCollectionDelegate: ChangeEventDelegate {
    typealias DocumentT = TodoItem
    
    private weak var vc: TodoTableViewController?
    init(_ vc: TodoTableViewController) {
        self.vc = vc
    }
    
    func onEvent(documentId: BSONValue, event: ChangeEvent<TodoItem>) {
        guard let vc = self.vc else {
            return
        }
        
        guard let id = event.documentKey["_id"] else {
            return
        }
        
        if event.operationType == .delete {
            guard let idx = vc.todoItems.firstIndex(where: { bsonEquals($0.id, id) }) else {
                return
            }
            vc.todoItems.remove(at: idx)
        } else {
            if let index = vc.todoItems.firstIndex(where: { bsonEquals($0.id, id) }) {
                vc.todoItems[index] = event.fullDocument!
            } else {
                if !itemsCollection.sync.syncedIds.contains(where: { bsonEquals($0.value, id) }) {
                    try! itemsCollection.sync.sync(ids: [id])
                }
                vc.todoItems.append(event.fullDocument!)
            }
        }
        
        DispatchQueue.main.sync {
            let toast = try! vc.view.toastViewForMessage(
                "\(event.operationType) for item: '\(event.fullDocument?.task ?? "(removed)")'",
                title: "items",
                image: nil,
                style: toastStyle)
            //            vc.view.showToast(toast)
            
            vc.todoItems.sort()
            
            // if it's a change to the index, it will be handled elsewhere
            if event.updateDescription?.updatedFields["index"] == nil {
                vc.tableView.reloadData()
            }
        }
    }
}

class TodoTableViewController:
UIViewController, UITableViewDataSource, UITableViewDelegate, ErrorListener, BEMCheckBoxDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolBar: UIToolbar!
    
    private var userId: String? {
        return stitch.auth.currentUser?.id
    }
    
    fileprivate var todoItems = [TodoItem]()
    fileprivate var checkBoxAll: BEMCheckBox!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ToastManager.shared.isQueueEnabled = true
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.isEditing = true
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let addButton = UIBarButtonItem(barButtonSystemItem: .add,
                                        target: self,
                                        action: #selector(addTodoItem(_:)))
        let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash,
                                           target: self,
                                           action: #selector(removeAll(_:)))
        self.checkBoxAll = BEMCheckBox.init(frame: CGRect.init(x: self.view.frame.maxX - 10, y: self.toolBar.frame.maxY - 10, width: 30, height: 30))
        
        checkBoxAll.delegate = self
        self.toolBar.items?.append(addButton)
        self.toolBar.items?.append(flexSpace)
        self.toolBar.items?.append(deleteButton)
        self.toolBar.items?.append(flexSpace)
        self.toolBar.items?.append(UIBarButtonItem.init(customView: checkBoxAll))
        
        if stitch.auth.isLoggedIn {
            loggedIn()
        } else {
            doLogin()
        }
    }
    
    @objc func addTodoItem(_ sender: Any) {
        let alertController = UIAlertController.init(title: "Add Item", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "ToDo item"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            if let task = alertController.textFields?.first?.text {
                let todoItem = TodoItem.init(id: ObjectId(),
                                             ownerId: self.userId!,
                                             task: task,
                                             doneDate: nil,
                                             index: self.todoItems.count,
                                             checked: false)
                itemsCollection.sync.insertOne(document: todoItem) { result in
                    switch result {
                    case .failure(let e):
                        fatalError(e.localizedDescription)
                    case .success(let result): break
                    }
                    
                }
            }
        }))
        self.present(alertController, animated: true)
    }
    
    func didTap(_ checkBox: BEMCheckBox) {
        for var todoItem in todoItems {
            todoItem.checked = checkBox.on
        }
        tableView.reloadData()
    }
    
    @objc func removeAll(_ sender: Any) {
        itemsCollection.deleteMany(["owner_id": userId!,
                                    "checked": true]) { result in
                                        switch result {
                                        case .failure(let error):
                                            print(error.localizedDescription)
                                        case .success(let result): break
                                        }
        }
    }
    
    private func loggedIn() {
        // Configure sync to be remote wins on both collections meaning and conflict that occurs should
        // prefer the remote version as the resolution.
        itemsCollection.sync.configure(
            conflictHandler: DefaultConflictHandler<TodoItem>.remoteWins(),
            changeEventDelegate: ItemsCollectionDelegate(self),
            errorListener: self)
        
        itemsCollection.sync.find { result in
            switch result {
            case .success(let todos):
                self.todoItems = todos.map { $0 }.sorted()
                DispatchQueue.main.sync {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    private func doLogin() {
        stitch.auth.login(withCredential:
        AnonymousCredential()) {
            switch $0 {
            case .success(_):
                self.loggedIn()
            case .failure(let e):
                print("error logging in \(e)")
            }
        }
    }

    func on(error: DataSynchronizerError, forDocumentId documentId: BSONValue?) {
        DispatchQueue.main.sync {
            let toast = try! self.view.toastViewForMessage(
                "\(error)",
                title: nil,
                image: nil,
                style: toastStyle)
            self.view.showToast(toast)
        }
    }
    
    func tableView(_ tableView: UITableView,
                   shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView,
                   moveRowAt sourceIndexPath: IndexPath,
                   to destinationIndexPath: IndexPath) {
        let itemToMove = todoItems[sourceIndexPath.row]
        todoItems.remove(at: sourceIndexPath.row)
        todoItems.insert(itemToMove, at: destinationIndexPath.row)
        todoItems.indices.forEach({ index in
            if todoItems[index].index != index {
                todoItems[index].index = index
            }
        })
        todoItems.sort()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoTableViewCell",
                                                 for: indexPath) as! TodoTableViewCell
        if todoItems.count >= indexPath.item {
            cell.set(todoItem: todoItems[indexPath.item])
        }
        return cell
    }
}
