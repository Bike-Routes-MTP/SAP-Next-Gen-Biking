import UIKit
import PopupDialog

class GroupListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Properties
    var groups = [Group]()
    
    
    @IBOutlet weak var groupTableView: UITableView!
    @IBOutlet weak var createGroupBtn: UIButton!
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(GroupListViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.orange
        
        return refreshControl
    }()
    
    //MARK: Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createGroupBtn.setTitle(NSLocalizedString("createGroupBtn", comment: ""), for: .normal)
        
        groupTableView.dataSource = self
        groupTableView.delegate = self
        
        loadGroups()
        
        self.groupTableView.addSubview(self.refreshControl)
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        loadGroups()
        self.groupTableView.reloadData()
        refreshControl.endRefreshing()
    }

    //MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "GroupTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? GroupTableViewCell  else {
            fatalError("Fatal Error")
        }
        
        // Fetches the appropriate friend for the data source layout.
        let friend = groups[indexPath.row]
        
        cell.nameLabel.text = friend.name
        let subTitle = friend.datum + ", " + friend.startLocation
        cell.timeLocationLabel.text = subTitle
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //Unassign from group
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .default, title: " X        ", handler: { (action, indexPath) in
            
            //Delete Alert
            let deleteAlert = UIAlertController(title: NSLocalizedString("unassignGroupTitle", comment: ""), message: NSLocalizedString("unassignGroupMsg", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            
            deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
                
                let id = String(self.groups[indexPath.row].id)
                
                ClientService.deleteUserFromGroup(userId: (KeychainService.loadEmail() ?? "") as String, groupId: id, completion: { (httpCode, error) in
                    if error == nil {
                        if(httpCode == 200) {
                            self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("unassignedTitle", comment: ""), message: NSLocalizedString("unassignedMsg", comment: "")), animated: true, completion: nil)
                        } else {
                            self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("errorOccuredDialogTitle", comment: ""), message: NSLocalizedString("errorOccuredDialogMsg", comment: "")), animated: true, completion: nil)
                        }
                    } else {
                        self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("errorOccuredDialogTitle", comment: ""), message: NSLocalizedString("errorOccuredDialogMsg", comment: "")), animated: true, completion: nil)
                    }
                })
                
                self.groups.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }))
            
            deleteAlert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: { (action: UIAlertAction!) in
                
            }))
            
            self.present(deleteAlert, animated: true, completion: nil)
            
        })
        deleteAction.backgroundColor = UIColor(red: 190/255, green: 51/255, blue: 43/255, alpha: 1)
        
        return [deleteAction]
    }
    
    //MARK: Private Methods
    
    private func loadGroups() {
        
        if let userMail = KeychainService.loadEmail() as String? {
            //Show activity indicator
            let activityAlert = UIAlertCreator.waitAlert(message: NSLocalizedString("pleaseWait", comment: ""))
            present(activityAlert, animated: false, completion: nil)
            
            ClientService.getGroupList(mail: userMail, completion: { (data, error) in
                if error == nil {
                    //Clear groups array
                    self.groups.removeAll()
                    
                    guard let responseData = data else {
                        //Dismiss activity indicator
                        activityAlert.dismiss(animated: false, completion: nil)
                        //An error occured
                        self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("errorOccuredDialogTitle", comment: ""), message: NSLocalizedString("errorOccuredDialogMsg", comment: "")), animated: true, completion: nil)
                        return
                    }
                    
                    //Construct group array
                    if let groupList = responseData["groups"] as? [[String: AnyObject]] {
                        
                        for group in groupList {
                            
                            let datumString = String(describing: group["datum"]!)
                            let index = datumString.index(datumString.startIndex, offsetBy: 16)
                            let datumBefore = datumString.substring(to: index).replacingOccurrences(of: "-", with:".")
                            let datum = datumBefore.replacingOccurrences(of: "T", with:" ")
                            
                            guard let groupEntity = Group(id: (group["groupId"] as? Int)!, name: (group["name"] as? String)!, datum: datum, startLocation: (group["startLocation"] as? String)!, destination: (group["destination"] as? String)!, text: (group["description"] as? String)!, owner: (group["owner"] as? String)!, privateGroup: (group["privateGroup"] as? Int)!) else {
                                activityAlert.dismiss(animated: false, completion: nil)
                                //An error occured
                                self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("errorOccuredDialogTitle", comment: ""), message: NSLocalizedString("errorOccuredDialogMsg", comment: "")), animated: true, completion: nil)
                                return
                            }
                            self.groups.append(groupEntity)
                        }
                    }
                    
                    self.groupTableView.reloadData()
                    //Dismiss activity indicator
                    activityAlert.dismiss(animated: false, completion: nil)
                    
                } else {
                    if error == ClientServiceError.notFound {
                        //Dismiss activity indicator
                        activityAlert.dismiss(animated: false, completion: nil)
                        /*
                        //No groups found
                        DispatchQueue.main.async {
                            self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("noGroupsDialogTitle", comment: ""), message: NSLocalizedString("noGroupsDialogMsg", comment: "")), animated: true, completion: nil)
                        }
 */
                    } else {
                        //Dismiss activity indicator
                        activityAlert.dismiss(animated: false, completion: nil)
                        
                        //An error occured in the app
                        DispatchQueue.main.async {
                            self.present(UIAlertCreator.infoAlert(title: NSLocalizedString("errorOccuredDialogTitle", comment: ""), message: NSLocalizedString("errorOccuredDialogMsg", comment: "")), animated: true, completion: nil)
                        }
                    }
                }
            })
        }
    }
    
    
    //MARK: Actions
    @IBAction func onPressOpenCreateGroup(_ sender: Any) {
        
        /*
        let storyboard = UIStoryboard(name: "Social", bundle: nil)
        let ratingVC = storyboard.instantiateViewController(withIdentifier: "CreateGroupPopupViewController")
        
        // Create the dialog
        let popup = PopupDialog(viewController: ratingVC, buttonAlignment: .horizontal, transitionStyle: .bounceDown, gestureDismissal: true)
        
        // Present dialog
        present(popup, animated: true, completion: nil)
        */
    }
    
    
}
