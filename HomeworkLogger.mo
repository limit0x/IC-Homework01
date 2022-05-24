// Persistent logger keeping track of what is going on.

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Deque "mo:base/Deque";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

import Logger "mo:ic-logger/Logger";

import TextLogger "TextLogger";

shared(msg) actor class HomeworkLogger() {
    
  var canisters : List.List<TextLogger> = List.nil();
  var canister : TextLogger = await TextLogger();
  var nextCanister: TextLogger = await TextLogger();
  var numOfLines: Nat = 0;
  var perLimit: Nat = 100;


  public type View<A> = {
    start_index: Nat;
    messages: [A];
  };
  // Add a set of messages to the log.
  public shared (msg) func append(msgs: [Text]) {
    
    canister.append(msgs);
    numOfLines += 1;
    if(numOfLines == perLimit) {
        canisters := List.push(canisters, canister);
        canister := nextCanister;
        num_of_lines = 0;
        nextCanister := await TextLogger();
    }
  };

  // Return the messages between from and to indice (inclusive).
  public shared query (msg) func view(from: Nat, to: Nat) : async Logger.View<Text> {
      
    assert(to >= from);
    let buf = Buffer.Buffer<Text>(to - from + 1);
    var segmentStart = from;

    while(segmentStart <= to) {
      let canisterIndex = segmentStart / perLimit;
      let canisterEnd = canisterIndex * perLimit + perLimit - 1;
      if(canisterEnd > to) {
          canisterEnd := to;
      };
      let segmentView : View<Text> = await canisters.get(canisterIndex).view(segmentStart, canisterEnd);
      var i = 0;
      while(i < segmentView.messages.size()) {
          buf.add(segmentView.messages[i])
          i += 1;
      };
      segmentStart := canisterEnd + 1;
    };
    {
        start_index: from;
        messages: buf.toArray();
    };
  };

}
