import UIKit;
import  Foundation;
import Firebase;

class AppData: NSObject
{
    static let sharedInstance = AppData();
    
    public var dataNode: DatabaseReference;
    
    public override init()
    {
        FirebaseApp.configure();
        dataNode = Database.database().reference().child("data");
    }
    
    struct UserStruct
    {
        var name: String = "";
        var email: String = "";
        var uid: String = "";
    }
    
    struct ItemStruct
    {
        var itemName: String = "";
        var itemPurchased: Bool = false;
        var itemTime: String = "";
    }
    
    struct GroceryListStruct
    {
        var listName: String = "";
        var listItems : Array<ItemStruct> = Array();
        var listOwner: UserStruct = UserStruct();
    }
    
    struct InvitationStruct
    {
        var listName: String = "";
        var ownerName: String  = "";
        var ownerUid: String = "";
        var ownerEmail: String = "";
    }
    
    var curUser: UserStruct?;
    var invitationsCoords: Array<InvitationStruct> = Array<InvitationStruct>();
    var onlineLST: Array<GroceryListStruct> = Array<GroceryListStruct>();
    var offlineLST: Array<GroceryListStruct> = Array<GroceryListStruct>();
    var currentLST: Array<GroceryListStruct> = Array<GroceryListStruct>();
    var invitationLst: Array<GroceryListStruct> = Array<GroceryListStruct>();
    
    
    
    func prepareFirstLists()
    {
        let timeNow = String (describing: Date());
        

        let item_1 : ItemStruct = ItemStruct(itemName: "Milk",
                                             itemPurchased: false,
                                             itemTime: timeNow);
        
        let item_2 : ItemStruct = ItemStruct(itemName: "Bread",
                                             itemPurchased: true,
                                             itemTime: timeNow);
        
        var items: Array<ItemStruct> = Array < ItemStruct>();
        items.append(item_1);
        items.append(item_2);
        
        currentLST.append(GroceryListStruct(listName: "Sample List", listItems: items, listOwner: curUser!));
        

        items = Array <ItemStruct>();
        
        items.append(ItemStruct(itemName: "Pens",
                                itemPurchased: false,
                                itemTime: timeNow));
        
        items.append(ItemStruct(itemName: "Pencils",
                                itemPurchased: true,
                                itemTime: timeNow));
        
        
        currentLST.append(GroceryListStruct(listName: "Office Suplies List", listItems: items, listOwner: curUser!));

        
        writeDataToDisk();
    }
    
    func setUser(inpName: String, inpEmail: String, inpUid: String)
    {
        let tempUser: UserStruct = UserStruct(name: inpName,
                                              email: inpEmail,
                                              uid: inpUid);
        
        for var anyList in currentLST
        {
            if ( anyList.listOwner.uid == curUser?.uid)
            {
                anyList.listOwner = tempUser;
            }
        }
        
        curUser = tempUser;
        
        self.writeDataToDisk();
        self.writeUserToDisk();
    }
    
    func writeDataToDisk ()
    {
        let documentDirURL = try! FileManager.default.url(for: .documentDirectory,
                                                          in: .userDomainMask,
                                                          appropriateFor: nil,
                                                          create: true);
        
        let dataFileURL = documentDirURL.appendingPathComponent("data").appendingPathExtension("json");
        
        let toWriteListsArr: NSMutableArray = NSMutableArray();
        
        for anyList:GroceryListStruct in currentLST
        {
            if ( anyList.listOwner.uid == curUser?.uid)
            {
                let itsName: String = anyList.listName;
                               
                let userDict : [String : String] = ["name" : curUser!.name,
                                                    "email" : curUser!.email,
                                                    "uid" : curUser!.uid];
                
                let toWriteItemsArr: NSMutableArray = NSMutableArray();
                
                for anyItem:ItemStruct in anyList.listItems
                {
                    let thisItem : [String : String] = ["itemName" : anyItem.itemName,
                                                        "itemPurchased" : String(anyItem.itemPurchased),
                                                        "itemTime" : anyItem.itemTime];
                    
                    toWriteItemsArr.add(thisItem);
                }
                
                let listDict: [String : Any] = ["listName" : itsName,
                                                "listItems" : toWriteItemsArr,
                                                "listOwner" : userDict];
                
                toWriteListsArr.add(listDict);
            }
        }
        
        let jsonData = try? JSONSerialization.data(withJSONObject:  toWriteListsArr,
                                                   options: JSONSerialization.WritingOptions(rawValue: 0));
        
        let string = NSString (data: jsonData!,
                               encoding: String.Encoding.utf8.rawValue);
        do
        {
            try string?.write(to: dataFileURL,
                              atomically: true,
                              encoding: String.Encoding.utf8.rawValue);
        }
        catch _ as NSError
        {
            
        }
    }
    
    func writeUserToDisk()
    {
        let docsURL = try! FileManager.default.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true);
        
        let userFileURL = docsURL.appendingPathComponent("user").appendingPathExtension("json");
        
        let userDict : [String : String] = ["name" : (curUser?.name)!,
                                            "email" : (curUser?.email)!,
                                            "uid" : (curUser?.uid)!];
        
        
        let jsonData = try? JSONSerialization.data(withJSONObject: userDict,
                                                   options: JSONSerialization.WritingOptions(rawValue: 0));
        
        let string = NSString (data: jsonData!,
                               encoding: String.Encoding.utf8.rawValue);
        
        do
        {
            try string?.write(to: userFileURL,
                              atomically: true,
                              encoding: String.Encoding.utf8.rawValue);
        }
        catch _ as NSError
        {
            
        }
    }
    
    func readUserFromDisk ()
    {
        var filePath = "";
        // Fine documents directory on device
        let dirs : [String] = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                                  FileManager.SearchPathDomainMask.allDomainsMask,
                                                                  true)
        
        filePath = dirs[0].appendingFormat("/" + "user.json");
        
        let fileManager = FileManager.default
        
        // Check if file exists
        if fileManager.fileExists(atPath: filePath)
        {
            do
            {
                let docsURL = try! FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: true);
                
                let userFileURL = docsURL.appendingPathComponent("user").appendingPathExtension("json");
                
                let readUserFile = try! Data(contentsOf: userFileURL, options: []);
                let readUserDict = try! JSONSerialization.jsonObject(with: readUserFile, options: []) as! Dictionary<String, String>;
                
                let readName: String = (readUserDict["name"])! as String;
                let readEmail: String = (readUserDict["email"])! as String;
                let readUid: String = (readUserDict["uid"])! as String;
                
                curUser = UserStruct(name: readName, email: readEmail, uid: readUid);
            }
        }
    }
    
    func compareShoppingLists(inpA:Array<GroceryListStruct>, inpB: Array<GroceryListStruct>) -> Array<GroceryListStruct>
    {
        var combinedLists: Array<GroceryListStruct> = Array<GroceryListStruct>();

        // first, if there is a list in one that is not in other, just copy it
        
        var listA: Array<GroceryListStruct> = inpA;
        var listB: Array<GroceryListStruct> = inpB;
        

        for a : GroceryListStruct in listA
        {
            var aIsUnique: Bool = true;
            for anyList : GroceryListStruct in listB
            {
                if(a.listName == anyList.listName)
                {
                    aIsUnique = false;
                }
            }
            // if a is still unique
            if ( aIsUnique)
            {
                combinedLists.append(a);
            }
        }
        
        // do the same for list B
        for b : GroceryListStruct in listB
        {
            var bIsUnique: Bool = true;
            for anyList : GroceryListStruct in listA
            {
                if(b.listName == anyList.listName)
                {
                    bIsUnique = false;
                }
            }
            // if a is still unique
            if ( bIsUnique)
            {
                combinedLists.append(b);
            }
        }
        
        // now remove the unique and added from each of the two lists
        for any: GroceryListStruct in combinedLists
        {
            if let ind = listA.index(where: { (item:GroceryListStruct) -> Bool in
                item.listName == any.listName
            })
            {
                listA.remove(at: ind);
            }
            
            if let ind = listB.index(where: { (item:GroceryListStruct) -> Bool in
                item.listName == any.listName
            })
            {
                listB.remove(at: ind);
            }
        }
        
        for anyListA:GroceryListStruct in listA
        {
            var thisListResultItems: Array<ItemStruct> = Array<ItemStruct>();
            var counterPartList : GroceryListStruct = GroceryListStruct();

            for anyListB : GroceryListStruct in listB
            {
                if ( anyListB.listName == anyListA.listName)
                {
                    counterPartList = anyListB;
                    break;
                }
            }
            
            for anyItem : ItemStruct in anyListA.listItems
            {
                var thisItemWasFound : Bool = false;
                for counterItem : ItemStruct in counterPartList.listItems
                {
                    if ( anyItem.itemName == counterItem.itemName)
                    {
                        thisItemWasFound = true;
                        let dateFormatter = DateFormatter();
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
                        let readTimeAnyItem: Date = dateFormatter.date(from: anyItem.itemTime)!;
                        let readTimeCounterItem: Date = dateFormatter.date(from: counterItem.itemTime)!;
                        
                        if (readTimeAnyItem > readTimeCounterItem)
                        {
                            thisListResultItems.append(anyItem);
                        }
                        else
                        {
                            thisListResultItems.append(counterItem);
                        }
                    }
                }
                // if we reached here and the item wasn't found
                if ( thisItemWasFound == false)
                {
                    thisListResultItems.append(anyItem);
                }
            }
            
            for anyCounterItem : ItemStruct  in counterPartList.listItems
            {
                var thisItemIsAreadyAdded : Bool = false;
                for anyItem in anyListA.listItems
                {
                    if ( anyCounterItem.itemName == anyItem.itemName)
                    {
                        thisItemIsAreadyAdded = true;
                    }
                }
                if ( thisItemIsAreadyAdded == false)
                {
                    thisListResultItems.append(anyCounterItem);
                }
            }
            
            combinedLists.append(GroceryListStruct(listName: anyListA.listName,
                                                   listItems: thisListResultItems,
                                                   listOwner: anyListA.listOwner));
        }
        return combinedLists;
    }
    
    func saveListOnCloud (inpList: GroceryListStruct)
    {
        if (Auth.auth().currentUser == nil)
        {
            return
        }
        
        let itsName: String = inpList.listName;
        
        // CHECK THIS IN XAMARIN to learn which user goes up to cloud
        let userDict : [String : String] = ["name" : curUser!.name,
                                            "email" : curUser!.email,
                                            "uid" : curUser!.uid];
        
        var itemsDict: [String : Any] = Dictionary<String , Any>();
        
        for anyItem in inpList.listItems
        {
            let thisItem : [String : String] = ["itemName" : anyItem.itemName,
                                                "itemPurchased" : String(anyItem.itemPurchased),
                                                "itemTime" : anyItem.itemTime];
            
            itemsDict[anyItem.itemName] = thisItem;
        }
        
        let listDict: [String : Any] = ["listName" : itsName,
                                        "listItems" : itemsDict,
                                        "listOwner" : userDict];
        
        dataNode.child(curUser!.uid).child("myLists").child(itsName).setValue(listDict);
    }
    
    func deleteListOnCloud (inpList: GroceryListStruct)
    {
        if (Auth.auth().currentUser == nil)
        {
            return
        }
        
        let listNode : DatabaseReference = dataNode.child(inpList.listOwner.uid).child("myLists").child(inpList.listName);
        listNode.removeValue();
    }
    
    func saveItemOnCloud(thisItem:ItemStruct, thisList:GroceryListStruct)
    {
        if (Auth.auth().currentUser == nil)
        {
            return
        }
        
        
        
        let itemDict : [String : String] = ["itemName" : thisItem.itemName,
                                            "itemPurchased" : String(thisItem.itemPurchased),
                                            "itemTime" : thisItem.itemTime];
        dataNode
            .child(curUser!.uid)
            .child("myLists")
            .child(thisList.listName)
            .child("listItems")
            .child(thisItem.itemName)
            .setValue(itemDict);
    }
    
    func changeItemPurchasedOnCloud (inpItem: ItemStruct, inpList: GroceryListStruct)
    {
        if (Auth.auth().currentUser == nil)
        {
            return
        }
        
        let itemNode : DatabaseReference = dataNode
            .child(inpList.listOwner.uid)
            .child("myLists")
            .child(inpList.listName)
            .child("listItems").child(inpItem.itemName);
        
        itemNode.child("itemPurchased").setValue(String(inpItem.itemPurchased));
        itemNode.child("itemTime").setValue(inpItem.itemTime);
    }
    
    func deleteItemOnCloud (inpItem: ItemStruct, inpList: GroceryListStruct)
    {
        if (Auth.auth().currentUser == nil)
        {
            return
        }
        
        let itemNode : DatabaseReference = dataNode
            .child(inpList.listOwner.uid)
            .child("myLists")
            .child(inpList.listName)
            .child("listItems").child(inpItem.itemName);
        
        itemNode.removeValue();
    }
    
    func readDataFromCloud ()
    {
        onlineLST = Array<GroceryListStruct>();
        
        let userID = Auth.auth().currentUser?.uid;
        dataNode.child(userID!).observeSingleEvent(of: .value, with:
        { (snapshot) in
            let value = snapshot.value as? NSDictionary;

            if ( value!["myLists"] != nil)
            {
                let lists : [String : Any] = value!["myLists"] as! Dictionary <String, Any>;
                
                for any in lists.values
                {
                    let readList = any as! Dictionary<String, Any>;
                    let readListName : String = readList["listName"] as! String;
                    
                    let readListOwner : [String : String] = readList["listOwner"] as! Dictionary<String, String>;
                    let thisListUser : UserStruct = UserStruct(name: readListOwner["name"]!,
                                                               email: readListOwner["email"]!,
                                                               uid: readListOwner["uid"]!);
                    
                    var thisListItems : Array<ItemStruct> = Array<ItemStruct>();
                    if ( readList["listItems"] != nil)
                    {
                        let listItems : [String : Any] = readList["listItems"] as! Dictionary<String, Any>;
                        
                        
                        for eachItem in listItems.values
                        {
                            let item = eachItem as! Dictionary <String , Any>;
                            
                            let readItemName = item["itemName"] as! String;
                            let readItemPurchasedStr = item["itemPurchased"] as! String;
                            
                            var readItemPurchased : Bool = false;
                            
                            if (readItemPurchasedStr == "True" || readItemPurchasedStr == "true")
                            {
                                readItemPurchased = true;
                            }
                            
                            let readItemTime = item["itemTime"] as! String;
                            
                            thisListItems.append(ItemStruct(itemName: readItemName,
                                                            itemPurchased: readItemPurchased,
                                                            itemTime: readItemTime));
                        }
                    }
                    
                    let thisList : GroceryListStruct = GroceryListStruct (listName: readListName,
                                                                          listItems: thisListItems,
                                                                          listOwner: thisListUser);
                    
                    self.onlineLST.append(thisList);
                }
            }
        })
        { (error) in
           
        }
    }
    
    func writeDataToCloud()
    {
        if (Auth.auth().currentUser == nil)
        {
            return
        }
        
        for anyList : GroceryListStruct in currentLST
        {
            if ( anyList.listOwner.uid == curUser?.uid)
            {
                saveListOnCloud(inpList: anyList);
            }
        }
    }
    
    func readDataFromDisk ()
    {
        var filePath = "";
        // Fine documents directory on device
        let dirs : [String] = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                                  FileManager.SearchPathDomainMask.allDomainsMask,
                                                                  true)
        
        filePath = dirs[0].appendingFormat("/" + "data.json");
        
        
        let fileManager = FileManager.default
        
        // Check if file exists
        if fileManager.fileExists(atPath: filePath)
        {
            offlineLST = Array<GroceryListStruct>();
            
            do
            {
                let docsURL = try! FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: true);
                
                let dataFileURL = docsURL.appendingPathComponent("data").appendingPathExtension("json");
                
                let readDataFile = try! Data(contentsOf: dataFileURL, options: []);
                let readDataArr : NSArray = try! JSONSerialization.jsonObject(with: readDataFile, options: []) as! NSArray;
                
                for anyList in readDataArr
                {
                    var thisList : GroceryListStruct = GroceryListStruct();
                    
                    var thisListDict : [String : Any] = anyList as! Dictionary<String, Any>;
                    
                    thisList.listName = thisListDict["listName"] as! String;
                    
                    var listOwnerDict : [String: String] = thisListDict["listOwner"] as! Dictionary<String, String>;
                    
                    let readName: String = (listOwnerDict["name"])! as String;
                    let readEmail: String = (listOwnerDict["email"])! as String;
                    let readUid: String = (listOwnerDict["uid"])! as String;
                    
                    let listOwner : UserStruct = UserStruct(name: readName, email: readEmail, uid: readUid);
                    thisList.listOwner = listOwner;
                    
                    let readItemsArr : NSArray = thisListDict["listItems"] as! NSArray;
                    
                    var listItemsArr : Array<ItemStruct> = Array<ItemStruct>();
                    for anyItem in readItemsArr
                    {
                        
                        var thisItemDict : [String : String] = anyItem as! Dictionary<String, String>;
                        
                        let readItemName: String = (thisItemDict["itemName"])! as String;
                        let readItemPurchasedStr: String = (thisItemDict["itemPurchased"])! as String;
                        var readItemPurchased : Bool = false;
                        
                        if (readItemPurchasedStr == "True" || readItemPurchasedStr == "true")
                        {
                            readItemPurchased = true;
                        }
                        
                        let readItemTime: String = (thisItemDict["itemTime"])! as String;
                        
                        
                        let thisItem : ItemStruct = ItemStruct(itemName: readItemName,
                                                               itemPurchased: readItemPurchased,
                                                               itemTime: readItemTime);
                        
                        listItemsArr.append(thisItem);
                    }
                    
                    thisList.listItems = listItemsArr;
                    
                    offlineLST.append(thisList);
                }
            }
        }
    }
    
    func removeInvitation(inpInvite: InvitationStruct)
    {
        if (Auth.auth().currentUser == nil)
        {
            return
        }
        
        let invitationTitle : String = inpInvite.ownerUid + " | " + inpInvite.listName;
        let invitationNode : DatabaseReference = dataNode.child(curUser!.uid).child("myInvitations").child(invitationTitle);
        invitationNode.removeValue();
    }
    
    func readInvitedCoordinates ()
    {
        invitationsCoords = Array<InvitationStruct>();
        
        dataNode.child(curUser!.uid).observeSingleEvent(of: .value, with:
        { (snapshot) in
                
            let value = snapshot.value as? NSDictionary;
            
            if ( value?["myInvitations"] != nil)
            {
                let allCoordData : [String : Any] = value?["myInvitations"] as! Dictionary<String, Any>;
                

                for any in allCoordData.values
                {
                    let eachCoordAllVals = any as! Dictionary<String, Any>;

                    
                    let foundListName: String = eachCoordAllVals["listName"] as! String;
                    let foundOwnerUid: String = eachCoordAllVals["ownerUid"] as! String;
                    let foundOwnerName: String = eachCoordAllVals["ownerName"] as! String;
                    let foundOwnerEmail: String = eachCoordAllVals["ownerEmail"] as! String;
                    
                    self.invitationsCoords.append(InvitationStruct(listName: foundListName,
                                                                   ownerName: foundOwnerName,
                                                                   ownerUid: foundOwnerUid,
                                                                   ownerEmail: foundOwnerEmail));
                }
            }
            
            self.fetchInvitations();
       
        });
    }
    
    func fetchInvitations ()
    {
        invitationLst = Array<GroceryListStruct>();
        for anyCoord : InvitationStruct in invitationsCoords
        {
            let listName = anyCoord.listName;
            let ownerUid = anyCoord.ownerUid;
            
            dataNode.child(ownerUid).observeSingleEvent(of: .value, with:
            { (snapshot) in
                    
                let value = snapshot.value as? NSDictionary;
                
                if ( value?["myLists"] != nil)
                {
                    let lists : [String : Any] = value?["myLists"] as! Dictionary<String, Any>;
                    let thisListAllData : [String : Any] = lists[listName] as! Dictionary<String, Any>;
                    
                    
                    print ("thisListAllData is: \(thisListAllData)");
                    

                    
                    var thisListItems : Array<ItemStruct> = Array<ItemStruct>();
                    
                    if ( thisListAllData["listItems"] != nil)
                    {
                        let listItems : [String : Any] = thisListAllData["listItems"] as! Dictionary<String, Any>;
                        
                        
                        for eachItem in listItems.values
                        {
                            let item = eachItem as! Dictionary <String , Any>;
                            
                            let readItemName = item["itemName"] as! String;
                            let readItemPurchasedStr = item["itemPurchased"] as! String;
                            
                            var readItemPurchased : Bool = false;
                            
                            if (readItemPurchasedStr == "True" || readItemPurchasedStr == "true")
                            {
                                readItemPurchased = true;
                            }
                            
                            let readItemTime = item["itemTime"] as! String;
                            
                            thisListItems.append(ItemStruct(itemName: readItemName,
                                                            itemPurchased: readItemPurchased,
                                                            itemTime: readItemTime));
                        }
                    }
                    
                    let thisList : GroceryListStruct = GroceryListStruct (listName: listName,
                                                                          listItems: thisListItems,
                                                                          listOwner: UserStruct(name: anyCoord.ownerName,
                                                                                                email: anyCoord.ownerEmail,
                                                                                                uid: anyCoord.ownerUid));
                    self.invitationLst.append(thisList);
                }
            });
        }
    }
}
