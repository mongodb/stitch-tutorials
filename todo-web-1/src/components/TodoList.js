import React from "react";
import TodoItem from "./TodoItem";
import {app, items} from "./../stitch";

var TodoList = class extends React.Component {

   loadList() {
      console.log(app.auth.user);
      let obj = this;
      items.find({}, {limit: 1000}).asArray().then(docs => {
         obj.setState({ items: docs, requestPending: false });
      });
   }

constructor(props) {
   super(props);

   this.state = {
      items: []
   };
}


checkHandler(id, status) {
   items.updateOne({ _id: id }, { $set: { checked: status } }).then(() => {
      this.loadList();
   }, { rule: "checked" });
}

componentDidMount() {
   this.loadList();
}

addItem(event) {
   if (event.keyCode != 13) {
      return;
   }
   this.setState({ requestPending: true });
   items.insertOne({ text: event.target.value, owner_id: app.auth.user.id })
      .then(() => {
      this._newitem.value = "";
      this.loadList();
      });
}

clear() {
   this.setState({ requestPending: true });
   items.deleteMany({ checked: true }).then(() => {
      this.loadList();
   });
}

setPending() {
   this.setState({ requestPending: true });
}

render() {
   let foo = (
      <div>
      <div className="controls">
         <input
            type="text"
            className="new-item"
            placeholder="add a new item and hit <enter>"
            ref={n => {
            this._newitem = n;
            }}
            onKeyDown={e => this.addItem(e)}
         />
         {this.state.items.filter(x => x.checked).length > 0
            ? <div
               href=""
               className="cleanup-button"
               onClick={() => this.clear()}
            >
               delete selected item(s)
            </div>
            : null}
      </div>
      <ul className="items-list">
         {this.state.items.length == 0
            ? <div className="list-empty-label">empty list.</div>
            : this.state.items.map(item => {
               return (
                  <TodoItem
                  key={item._id.toString()}
                  item={item}
                  items={this.items}
                  onChange={() => this.loadList()}
                  onStartChange={() => this.setPending()}
                  />
               );
            })}
      </ul>
      </div>
   );
   return foo;
}
};

TodoList.displayName = "TodoList";
export default TodoList;