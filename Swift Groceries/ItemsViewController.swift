import UIKit;
import Firebase;

class ItemsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate
{

    public var curListInt: Int = 0;
    
    
    @IBOutlet weak var newItemTextField: UITextField!
    @IBOutlet weak var itemsTableView: UITableView!
    @IBOutlet weak var shareThisButton: UIButton!
    
    
    func inviteThisPerson(inpEmailAddress: String)
    {
        var inviteeUser : AppData.UserStruct = AppData.UserStruct();
        let ownerUser: AppData.UserStruct = AppData.sharedInstance.currentLST[curListInt].listOwner;
        let thisListName : String = AppData.sharedInstance.currentLST[curListInt].listName;
        
        AppData.sharedInstance.dataNode.observeSingleEvent(of: .value, with:
        { (snapshot) in
            let content = snapshot.value as? NSDictionary;
            
            for any in content!.allValues
            {
                let thisData : Dictionary < String, Any> = any as! Dictionary < String, Any>;
                
                if ( thisData["email"] as! String == inpEmailAddress)
                {
                    let foundName : String = thisData["name"] as! String;
                    let foundEmail : String = thisData["email"] as! String;
                    let foundUid : String = thisData["uid"] as! String;
                    inviteeUser = AppData.UserStruct(name: foundName,
                                                     email: foundEmail,
                                                     uid: foundUid);
                    break;
                }
            }
            
            let invitationTitle : String = ownerUser.uid + " | " + thisListName;
            
            let inviteeDict: [String : Any] = ["listName" : thisListName,
                                               "ownerUid" : ownerUser.uid,
                                               "ownerEmail" : ownerUser.email,
                                               "ownerName" : ownerUser.name];
            
            let inviteeNode : DatabaseReference = AppData.sharedInstance.dataNode.child(inviteeUser.uid);
            
            inviteeNode.child("myInvitations").child(invitationTitle).setValue(inviteeDict);
            
            self.alertShowMethod(titleStr: "Invitation Sent", messageStr: "You have successfully send an invitation");
        });
    }
    
    
    @IBAction func shareThisFunction(_ sender: Any)
    {
        var shareAlert: UIAlertController;
        
        shareAlert = UIAlertController (title: "Inviting Someone?",
                                        message: "Please enter the Email Address of the person you wish to invite to this list",
                                        preferredStyle: UIAlertControllerStyle.alert);
        
        shareAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler:
            {
                (UIAlertAction) in
                self.inviteThisPerson(inpEmailAddress: (shareAlert.textFields?[0].text)!);
        }));
        
        shareAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: nil));
        
        
        shareAlert.addTextField
            { (field) in
                field.placeholder = "Email Address";
                field.font = UIFont.systemFont(ofSize: 22);
        }
        
        self.present(shareAlert, animated: true, completion: nil);
    }
    
    
    func alertShowMethod(titleStr: String, messageStr: String)
    {
        let alert: UIAlertController = UIAlertController(title: titleStr,
                                                         message: messageStr,
                                                         preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil));
        self.present(alert, animated: true, completion: nil);
    }
    

    override func viewDidLoad()
    {
        super.viewDidLoad();

        self.title = AppData.sharedInstance.currentLST[curListInt].listName;
        
        newItemTextField.returnKeyType = UIReturnKeyType.done;
        newItemTextField.delegate = self;
        
        
        if (Auth.auth().currentUser == nil)
        {
            shareThisButton.isEnabled = false;
            shareThisButton.setTitle("You have to login", for: UIControlState.normal);
            shareThisButton.setTitleColor(UIColor.yellow, for: UIControlState.normal);
        }
    }

    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool
    {
        return true;
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder();
        return true;
    }

    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        let timeNow = String (describing: Date());
        
        let newItem: AppData.ItemStruct = AppData.ItemStruct(itemName: textField.text!,
                                                             itemPurchased: false,
                                                             itemTime: timeNow);
        
        AppData.sharedInstance.currentLST[curListInt].listItems.append(newItem);
        
        itemsTableView.reloadData();
        
        AppData.sharedInstance.writeDataToDisk();
        
        AppData.sharedInstance.saveItemOnCloud(thisItem: newItem, thisList: AppData.sharedInstance.currentLST[curListInt]);
        
        textField.text = "";
    }
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return AppData.sharedInstance.currentLST[curListInt].listItems.count;
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath);
        
        let itemForCell: AppData.ItemStruct = AppData.sharedInstance.currentLST[curListInt].listItems[indexPath.row];

        cell.textLabel?.text = itemForCell.itemName;
        
        if ( itemForCell.itemPurchased)
        {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 14);
            cell.accessoryType = UITableViewCellAccessoryType.checkmark;
            cell.backgroundColor = UIColor.darkGray;
            cell.textLabel?.textColor = UIColor.lightGray;
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: itemForCell.itemName);
            attributeString.addAttribute(NSStrikethroughStyleAttributeName,
                                         value: 2,
                                         range: NSMakeRange(0, attributeString.length));
            cell.textLabel?.attributedText = attributeString;
        }
        else
        {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16);
            cell.accessoryType = UITableViewCellAccessoryType.none;
            cell.backgroundColor = UIColor.white;
            cell.textLabel?.textColor = UIColor.black;

            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: itemForCell.itemName);
            
            attributeString.addAttribute(NSStrikethroughStyleAttributeName,
                                         value: 0,
                                         range: NSMakeRange(0, attributeString.length));
            cell.textLabel?.attributedText = attributeString;
        }
        
        return cell;
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        AppData.sharedInstance.currentLST[curListInt].listItems[indexPath.row].itemPurchased = !AppData.sharedInstance.currentLST[curListInt].listItems[indexPath.row].itemPurchased;
        

        AppData.sharedInstance.currentLST[curListInt].listItems[indexPath.row].itemTime = String (describing: Date());
        
        tableView.reloadData();
        
        
        let thisItem = AppData.sharedInstance.currentLST[curListInt].listItems[indexPath.row];
        
        AppData.sharedInstance.writeDataToDisk();
        
        AppData.sharedInstance.changeItemPurchasedOnCloud(inpItem: thisItem,
                                                          inpList: AppData.sharedInstance.currentLST[curListInt]);
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true;
    }
    
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String?
    {
            return "Delete This?";
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if (editingStyle == UITableViewCellEditingStyle.delete)
        {
            AppData.sharedInstance.deleteItemOnCloud(inpItem: AppData.sharedInstance.currentLST[curListInt].listItems[indexPath.row],
                                              inpList: AppData.sharedInstance.currentLST[curListInt]);
            
            AppData.sharedInstance.currentLST[curListInt].listItems.remove(at: indexPath.row);
            AppData.sharedInstance.writeDataToDisk();
            
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade);
        }
    }
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
    {
        return UITableViewCellEditingStyle.delete;
    }
}
