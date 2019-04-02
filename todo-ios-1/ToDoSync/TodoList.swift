import Foundation
import MongoSwift

struct TodoList: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "_id", todos
    }

    let id: String
    let todos: [ObjectId]?

    init(id: String) {
        self.id = id
        self.todos = nil
    }
}
