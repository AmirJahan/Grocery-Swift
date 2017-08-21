import UIKit;
import Firebase;



class ListsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var listsTableView: UITableView!
    @IBOutlet weak var profileButton: UIButton!
    
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated);
        listsTableView.reloadData();
    }
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
        
        AppData.sharedInstance.readUserFromDisk();
        
        if (AppData.sharedInstance.curUser == nil)
        {
            AppData.sharedInstance.setUser(inpName: "Mine", inpEmail: "defEmail", inpUid: "defUid");
            AppData.sharedInstance.prepareFirstLists();
            
            setProfileButton(statusStr: "Offline", bgColor: UIColor.yellow);
        }
        else
        {
            readData();
        }
 
        self.listsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell");
    }

    
    func readData()
    {
        AppData.sharedInstance.readDataFromDisk();
        
        if (Auth.auth().currentUser != nil) // ONLINE
        {
            AppData.sharedInstance.readDataFromCloud();
            AppData.sharedInstance.readInvitedCoordinates();
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute:
            {
                AppData.sharedInstance.currentLST = AppData.sharedInstance.compareShoppingLists(inpA: AppData.sharedInstance.offlineLST,
                                                                                                inpB: AppData.sharedInstance.onlineLST);
                
                for anyInvitedList in AppData.sharedInstance.invitationLst
                {
                    AppData.sharedInstance.currentLST.append(anyInvitedList);
                }
                
                AppData.sharedInstance.writeDataToDisk();
                AppData.sharedInstance.writeDataToCloud();
                
                
                self.setProfileButton(statusStr: "Online", bgColor: UIColor.green);
                self.listsTableView.reloadData();
            });
        }
        else // OFFLINE
        {
            AppData.sharedInstance.currentLST = AppData.sharedInstance.offlineLST;
            setProfileButton(statusStr: "Offline", bgColor: UIColor.yellow);
            self.listsTableView.reloadData();
        }
    }

    
    func setProfileButton(statusStr: String, bgColor: UIColor)
    {
        profileButton.setTitle(statusStr+"!", for: UIControlState.normal);
        profileButton.setTitleColor(bgColor, for: UIControlState.normal);
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return AppData.sharedInstance.currentLST.count;
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath);
        
        let thisList: AppData.GroceryListStruct = AppData.sharedInstance.currentLST[indexPath.row] ;
        
        cell.textLabel?.text = thisList.listName;
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 24);
        cell.detailTextLabel?.text = String(thisList.listItems.count) + " item(s)! for " + thisList.listOwner.name;

        if ( thisList.listOwner.uid != AppData.sharedInstance.curUser?.uid)
        {
            cell.detailTextLabel?.textColor = UIColor.red;
        }
        else
        {
            cell.detailTextLabel?.textColor = UIColor.darkGray;
        }
        
        if (indexPath.row % 2 == 1)
        {
            cell.backgroundColor = UIColor.init(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 1);
        }
        
        return cell;
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        self.performSegue(withIdentifier: "toItemsSegue", sender: indexPath.row);
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let itemsViewCtrlObj: ItemsViewController = segue.destination as! ItemsViewController;
        
        itemsViewCtrlObj.curListInt = sender as! Int;
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true;
    }
    
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String?
    {
        let thisList: AppData.GroceryListStruct = AppData.sharedInstance.currentLST[indexPath.row];
        if ( thisList.listOwner.uid == AppData.sharedInstance.curUser?.uid)
        {
            return "Delete " + thisList.listName + "?";
        }
        else
        {
            return "Reject " + thisList.listName + "?";
        }
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        let toDeletList: AppData.GroceryListStruct = AppData.sharedInstance.currentLST[indexPath.row];
        
        if (toDeletList.listOwner.uid == AppData.sharedInstance.curUser?.uid)
        {
            AppData.sharedInstance.deleteListOnCloud(inpList: toDeletList);
            
            AppData.sharedInstance.currentLST.remove(at: indexPath.row);
            AppData.sharedInstance.writeDataToDisk();
        }
        else
        {
            AppData.sharedInstance.currentLST.remove(at: indexPath.row);
            
            let listName: String = toDeletList.listName;
            let listOnwerUid: String = toDeletList.listOwner.uid;
            
            for any in AppData.sharedInstance.invitationsCoords
            {
                if ( any.listName == listName && any.ownerUid == listOnwerUid)
                {
                    AppData.sharedInstance.removeInvitation(inpInvite: any);
                    break;
                }
            }
        }
        
        tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade);
    }
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
    {
        return UITableViewCellEditingStyle.delete;
    }
    
    
    @IBAction func profileFunction(_ sender: Any)
    {
        var profilAlert: UIAlertController = UIAlertController();
        
        
        profilAlert = UIAlertController(title: "Profile Management",
                                        message: "What would you like to do?",
                                        preferredStyle: UIAlertControllerStyle.actionSheet);
        
        profilAlert.addAction(UIAlertAction(title: "Login",
                                            style: UIAlertActionStyle.default,
                                            handler:
                                                { (thisAlert) in
                                                    self.loginAlertView();
                                                }));
        
        profilAlert.addAction(UIAlertAction(title: "Register",
                                            style: UIAlertActionStyle.default,
                                            handler:
                                                { (thisAlert) in
                                                    self.registerAlertView();
                                                }));
        
        profilAlert.addAction(UIAlertAction(title: "Logout",
                                            style: UIAlertActionStyle.destructive,
                                            handler:
                                                { (thisAlert) in
                                                    self.logoutMethod();
                                                }));
        
        profilAlert.addAction(UIAlertAction(title: "Cancel",
                                            style: UIAlertActionStyle.cancel,
                                            handler: nil));
        
        
        present(profilAlert, animated: true, completion: nil);
    }
    
    
    func loginAlertView()
    {
        let loginAlert:UIAlertController = UIAlertController(title: "Login Online",
                                                             message: "Please enter your email and password",
                                                             preferredStyle: UIAlertControllerStyle.alert);
        
        loginAlert.addAction(UIAlertAction(title: "Login", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
            self.loginMethod(inpEmail: (loginAlert.textFields?[0].text)!,
                             inpPassword: (loginAlert.textFields?[1].text)!);
        }));
        
        loginAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: nil));
        
        
        loginAlert.addTextField
            { (field) in
                field.placeholder = "Email";
                field.font = UIFont.systemFont(ofSize: 22);
        }
        loginAlert.addTextField
            { (field) in
                field.placeholder = "Password";
                field.font = UIFont.systemFont(ofSize: 22);
                field.isSecureTextEntry = true;
        }
        
        self.present(loginAlert, animated: true, completion: nil);
    }
    
    
    func logoutMethod ()
    {
        let firebaseAuth = Auth.auth();
        do
        {
            try firebaseAuth.signOut();
            alertShowMethod(titleStr: "Signed Out", messageStr: "You are now logged out, you can continue working offline");
        }
        catch _ as NSError
        {
            
        }
        readData();
    }
    
    
    func loginMethod(inpEmail: String, inpPassword: String)
    {
        Auth.auth().signIn(withEmail: inpEmail, password: inpPassword)
        { (user, error) in
            if ( error == nil)
            {
                AppData.sharedInstance.setUser(inpName: user!.displayName!,
                                               inpEmail:  user!.email!,
                                               inpUid: user!.uid)
                
                self.alertShowMethod(titleStr: "Login Was Successful",
                                     messageStr: "Welcome back " + user!.displayName!);

                self.readData();
            }
        }
    }
    

    func registerAlertView()
    {
        let registerAlert:UIAlertController = UIAlertController(title: "Register Online",
                                                                message: "Please enter your name, email and password",
                                                                preferredStyle: UIAlertControllerStyle.alert);
        
        registerAlert.addAction(UIAlertAction(title: "Register", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
            self.registerMethod(inpName: (registerAlert.textFields?[0].text)!,
                                inpEmail: (registerAlert.textFields?[1].text)!,
                                inpPassword: (registerAlert.textFields?[2].text)!);
        }));
        
        registerAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: nil));
        
        
        registerAlert.addTextField
        { (field) in
            field.placeholder = "Name";
            field.font = UIFont.systemFont(ofSize: 22);
            field.keyboardType = UIKeyboardType.alphabet;
        }
    
        registerAlert.addTextField
        { (field) in
            field.placeholder = "Email";
            field.font = UIFont.systemFont(ofSize: 22);
            field.keyboardType = UIKeyboardType.emailAddress;
        }
        
        registerAlert.addTextField
        { (field) in
            field.placeholder = "Password";
            field.font = UIFont.systemFont(ofSize: 22);
            field.isSecureTextEntry = true;
        }
        
        self.present(registerAlert, animated: true, completion: nil);
    }
    
    
    func registerMethod(inpName: String, inpEmail: String, inpPassword: String)
    {
        Auth.auth().createUser(withEmail: inpEmail, password: inpPassword)
        { (user, error) in
            if (error == nil)
            {
                let changeRequest = user?.createProfileChangeRequest();
                changeRequest?.displayName = inpName;
                
                changeRequest?.commitChanges(completion:
                { (profError) in
                    if ( profError == nil)
                    {
                        let userDict : [String : String] = ["name" : inpName,
                                                            "email" : inpEmail,
                                                            "uid" : user!.uid];
                        
                        AppData.sharedInstance.setUser(inpName: inpName, inpEmail: inpEmail, inpUid: user!.uid);
                        
                        
                        AppData.sharedInstance.dataNode.child(AppData.sharedInstance.curUser!.uid).setValue(userDict);
                        
                        for any in AppData.sharedInstance.currentLST
                        {
                            let thisList = any ;
                            AppData.sharedInstance.saveListOnCloud(inpList: thisList);
                        }
                        self.readData();
                    }
                    else
                    {
                        
                    }
                });
            }
            else
            {
                
            }
        }
    }
    
    
    @IBAction func newListFunction(_ sender: Any)
    {
        let alert: UIAlertController = UIAlertController(title: "New Shopping List",
                                                         message: "Enter the name of your new shopping list.",
                                                         preferredStyle: UIAlertControllerStyle.alert);
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:
            { (UIAlertAction) in
                self.newListAlertOkAction(inpAlet: alert);
        }));
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil));
        
        alert.addTextField
            { (field) in
                field.placeholder = "new list name";
                field.font = UIFont.systemFont(ofSize: 22);
                field.textAlignment = NSTextAlignment.center;
        }
        
        self.present(alert, animated: true, completion: nil);
    }
    

    func newListAlertOkAction(inpAlet:UIAlertController)
    {
        let receivedName:String = inpAlet.textFields![0].text!;
        
        let newList: AppData.GroceryListStruct = AppData.GroceryListStruct (listName: receivedName,
                                                                            listItems: [],
                                                                            listOwner: AppData.sharedInstance.curUser!);
        
        AppData.sharedInstance.currentLST.append(newList);
        
        listsTableView.reloadData();
        AppData.sharedInstance.writeDataToDisk();
        
        AppData.sharedInstance.saveListOnCloud(inpList: newList);
    }
    
    
    func alertShowMethod(titleStr: String, messageStr: String)
    {
        let alert: UIAlertController = UIAlertController(title: titleStr,
                                                         message: messageStr,
                                                         preferredStyle: UIAlertControllerStyle.alert);
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel, handler: nil));
        self.present(alert, animated: true, completion: nil);
    }
}
