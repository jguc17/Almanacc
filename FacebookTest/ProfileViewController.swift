//
//  ProfileViewController.swift
//  FacebookTest
//
//  Created by Jeffrey Gu on 4/9/17.
//  Copyright © 2017 Jeffrey Gu. All rights reserved.
//

import Foundation
import UIKit
import FacebookCore
import FBSDKCoreKit
import FBSDKShareKit
import Firebase
import GoogleMaps
import GooglePlaces

//http://stackoverflow.com/questions/39325970/how-to-access-profile-picture-with-facebook-api-in-swift-3
//http://stackoverflow.com/questions/39813497/swift-3-display-image-from-url

class ProfileViewController: UIViewController, FBSDKAppInviteDialogDelegate, GMSAutocompleteFetcherDelegate, LocationDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var profileView: UIImageView!
    @IBOutlet weak var educationField: UITextField!
    @IBOutlet weak var workField: UITextField!
    
    @IBOutlet weak var locationField: UILabel!
    @IBOutlet weak var nameField: UILabel!
    
    @IBOutlet weak var locEditButton: UIButton!
    @IBOutlet weak var uniEditButton: UIButton!
    @IBOutlet weak var jobEditButton: UIButton!
    
    static let storyboardIdentifier = "ProfileViewController"
    
    var searchResultController: LocationSearchResultsController!
    var resultsArray = [String]()
    var gmsFetcher: GMSAutocompleteFetcher!
    
    let storageRef = FIRStorage.storage().reference()
    let ref = FIRDatabase.database().reference(fromURL: "https://almanaccfb.firebaseio.com/")
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        
        super.viewDidLoad()
        profileView.image = #imageLiteral(resourceName: "mr-incredible")    //default
        
        DispatchQueue.main.async {
            self.getProfileInfo()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        searchResultController = LocationSearchResultsController()
        searchResultController.delegate = self
        gmsFetcher = GMSAutocompleteFetcher()
        let filter = GMSAutocompleteFilter()
        filter.type = .city
        gmsFetcher.autocompleteFilter = filter
        gmsFetcher.delegate = self
        
    }
    
    func updateLocation(title: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                let userInfo = UserDefaults.standard.object(forKey: "userInfo") as? [String:Any] ?? [String:Any]()
                if let id = userInfo["id"] {
                    self.ref.child("users").child(id as! String).updateChildValues(["location": self.locationField.text ?? ""])
                    let eventString = self.nameField.text! + " moved to " + self.locationField.text!
                    self.addToFriendNewsFeed(event: eventString, ownID: id as! String)
                }
            }
        }
        self.locationField.text = title
//        self.locationField.setNeedsDisplay()
        
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.resultsArray.removeAll()
        gmsFetcher?.sourceTextHasChanged(searchText)
    }
        
    
    @IBAction func editLocation(_ sender: UIButton) {
        let searchController = UISearchController(searchResultsController: searchResultController)
        searchController.searchBar.delegate = self
        self.present(searchController, animated:true, completion: nil)
    }
    @IBAction func editUniversity(_ sender: UIButton) {
        let editStatus = !educationField.isUserInteractionEnabled
        educationField.isUserInteractionEnabled = editStatus
        
        if (editStatus) {
            // if enabled
            uniEditButton.setImage(#imageLiteral(resourceName: "check-icon"), for: .normal)
            educationField.becomeFirstResponder()
        }
        else {
            uniEditButton.setImage(#imageLiteral(resourceName: "pen-icon"), for: .normal)
            self.view.becomeFirstResponder()
            
            let userInfo = UserDefaults.standard.object(forKey: "userInfo") as? [String:Any] ?? [String:Any]()
            if let id = userInfo["id"] {
                self.ref.child("users").child(id as! String).updateChildValues(["education": self.educationField.text])
                let eventString = self.nameField.text! + " went to " + self.educationField.text!
                addToFriendNewsFeed(event: eventString, ownID: id as! String)
            }
        }
    }
    @IBAction func editJob(_ sender: UIButton) {
        let editStatus = !workField.isUserInteractionEnabled
        workField.isUserInteractionEnabled = editStatus
        
        if (editStatus) {
            // if enabled
            jobEditButton.setImage(#imageLiteral(resourceName: "check-icon"), for: .normal)
            workField.becomeFirstResponder()
        }
        else {
            jobEditButton.setImage(#imageLiteral(resourceName: "pen-icon"), for: .normal)
            self.view.becomeFirstResponder()
            let userInfo = UserDefaults.standard.object(forKey: "userInfo") as? [String:Any] ?? [String:Any]()
            if let id = userInfo["id"] {
                self.ref.child("users").child(id as! String).updateChildValues(["work": self.workField.text])
                let eventString = self.nameField.text! + " is now working for " + self.workField.text!
                addToFriendNewsFeed(event: eventString, ownID: id as! String)
            }
        }
    }
    
    @IBAction func inviteFriends(_ sender: UIButton) {
        print("Invite button tapped")
        
        let inviteDialog:FBSDKAppInviteDialog = FBSDKAppInviteDialog()
        if(inviteDialog.canShow()){
            
            let appLinkUrl:NSURL = NSURL(string: "https://fb.me/1886351618271924")!
            //let previewImageUrl:NSURL = NSURL(string: "http://yourwebpage.com/preview-image.png")!
            
            let inviteContent:FBSDKAppInviteContent = FBSDKAppInviteContent()
            inviteContent.appLinkURL = appLinkUrl as URL!
            //inviteContent.appInvitePreviewImageURL = previewImageUrl as URL!
            
            inviteDialog.content = inviteContent
            inviteDialog.delegate = self
            inviteDialog.show()
        }

    }
    
    func getProfilePicture() {
        //TODO: refactor this using the FacebookCore module instead of FBSDK?
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id,picture.width(198).height(198)"])
        graphRequest.start(completionHandler: { (connection, result2, error) -> Void in
            let data = result2 as! [String : AnyObject]
            let _loggedInUserSettingRecordName = data["id"] as? String // (forKey: "id") as? String
            let profilePictureURLStr = (data["picture"]!["data"]!! as! [String : AnyObject])["url"]
            
            print("got profile picture url: ", profilePictureURLStr ?? "N/A")
            
            if let urlPath = profilePictureURLStr {
            
                // Define a download task. The download task will download the contents of the URL as a Data object and then you can do what you wish with that data.
                let url = NSURL(string: urlPath as! String)
                let request = URLRequest(url: url as! URL)
                
                let downloadPicTask = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
                    // The download has finished.
                    if let e = error {
                        print("Error downloading profile picture: \(e)")
                    } else {
                        // No errors found, check HTTP response
                        if let res = response as? HTTPURLResponse {
                            print("Downloaded profile picture with response code \(res.statusCode)")
                            if let imageData = data {
                                // Convert Data into image and set profile
                                let image = UIImage(data: imageData)
                                self.profileView.image = image
                                self.storeProfilePic()
                            } else {
                                print("Couldn't get image: Image is nil")
                            }
                        } else {
                            print("Couldn't get HTTP response")
                        }
                    }
                }
                downloadPicTask.resume()
            }
        })
    }
    
    func storeProfilePic() {
        let userInfo = UserDefaults.standard.object(forKey: "userInfo") as? [String:Any] ?? [String:Any]()
        let id = userInfo["id"] as! String
        
        // TODO: tinker with compression quality or use png format?
        let imageData = UIImageJPEGRepresentation(self.profileView.image!, 0.9)!
        // set upload path
        let filePath = "\(id)/\("userPhoto")"
        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/jpg"
        
//        let storageRef = FIRStorage.storage().reference()
//        let ref = FIRDatabase.database().reference(fromURL: "https://almanaccfb.firebaseio.com/")
        
        
        self.storageRef.child(filePath).put(imageData, metadata: metaData){(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            else {
                //store download url in DB
                let downloadURL = metaData!.downloadURL()!.absoluteString
                self.ref.child("users").child(id).updateChildValues(["picture": downloadURL])
            }
        }
    }
    
    func queryLocationData(id:String) {
        let graphRequest = GraphRequest(graphPath: "/\(id)?fields=location")
        graphRequest.start { (urlResponse, requestResult) in
            switch requestResult {
            case .failed(let error):
                print(error)
            case .success(let graphResponse):
                print("success")
                if let responseDictionary = graphResponse.dictionaryValue {
                    dump(responseDictionary)
                    
                    let infoBank = responseDictionary["location"] as? [String:Any] ?? [String:Any]()
                    let country = infoBank["country"] as? String ?? "Mars"
                    let city = infoBank["city"] as? String ?? "Cityville"
                    let state = infoBank["state"] as? String ?? ""
                    
                    var verifiedLocation:String
                    if (state.isEmpty) {
                        verifiedLocation = city + ", " + country
                    }
                    else {
                        verifiedLocation = city + ", " + state + ", " + country
                    }
                    
                    
                    self.locationField.text = verifiedLocation
                    
                    let userInfo = UserDefaults.standard.object(forKey: "userInfo") as? [String:Any] ?? [String:Any]()
                    if let idString = userInfo["id"] {
                        
                        self.ref.child("users").child(idString as! String).updateChildValues(["location": verifiedLocation])
                    }
                    
                    
                }
            }
        }

    }
    
    func queryFB(flag:Bool) {
        if(!flag) {
            print("pulling profile info from Facebook Graph API")
            let params = ["fields":"name,email,education,location,work,hometown"]
            let graphRequest = GraphRequest(graphPath: "me", parameters: params)
            graphRequest.start { (urlResponse, requestResult) in
                switch requestResult {
                case .failed(let error):
                    print(error)
                case .success(let graphResponse):
                    if let responseDictionary = graphResponse.dictionaryValue {
                        dump(responseDictionary)
                        self.nameField.text = responseDictionary["name"] as? String ?? "Mr. Incredible"
                        
                        let id = responseDictionary["id"] as? String ?? "Invalid ID"
                        let educationList = responseDictionary["education"] as? [Any] ?? [Any]()
                        let schoolDict = educationList[educationList.count-1] as? [String:Any] ?? [String:Any]()
                        let detailedSchoolDict = schoolDict["school"] as? [String:Any] ?? [String:Any]()
                        self.educationField.text = detailedSchoolDict["name"] as? String ?? "Superhero University"
                        
                        let locationDict = responseDictionary["location"] as? [String:Any] ?? [String:Any]()
                        self.locationField.text = locationDict["name"] as? String ?? "Saint Louis, MO, United States"
                        
                        let locationID = locationDict["id"] as? String ?? ""
                        self.queryLocationData(id: locationID)
                        
                        
                        //Insert dictionary into Firebase
//                        let ref = FIRDatabase.database().reference(fromURL: "https://almanaccfb.firebaseio.com/")
                        //                    ref.childByAutoId().updateChildValues(responseDictionary, withCompletionBlock: {(err,ref) in
                        //                        if(err != nil){
                        //                            print(err)
                        //                            return
                        //                        }
                        //                    })
//                        ref.child("users").child(id).setValue(responseDictionary)
                        var storageDict:[String:Any] = ["id":id, "name": self.nameField.text, "education": self.educationField.text, "location":self.locationField.text, "work":self.workField.text]
                        var newsfeed = [String : Any]()
                        newsfeed["0"] = ["You joined Almanacc!", NSDate().timeIntervalSince1970, id ]
                        //storageDict["newsfeed"] = newsfeed
                        self.ref.child("users").child(id).setValue(storageDict)
                        self.ref.child("newsfeed").child(id).setValue(newsfeed)
                    }
                }
            }
            getProfilePicture()
        }
        else {
            print("already have profile info")
        }
    }
    
    func getProfileInfo() {
        // pull from UserDefaults for Facebook ID, check against Firebase
        // if exists, no need to make a Graph Request
        var existsInDB = false
        let userInfo = UserDefaults.standard.object(forKey: "userInfo") as? [String:Any] ?? [String:Any]()
        if let keyExists = userInfo["id"] {
//            print("indexing Firebase with id: ", keyExists)
//            let ref = FIRDatabase.database().reference(fromURL: "https://almanaccfb.firebaseio.com/")
            self.ref.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
                let enumerator = snapshot.children
                while let child = enumerator.nextObject() as? FIRDataSnapshot {
                    let childDict = child.value as? [String:Any] ?? [String:Any]()
                    let id = childDict["id"] as? String ?? "??"
                    if(id == keyExists as? String) {
                        existsInDB = true   //mark flag
                        
                        //education
                        self.educationField.text = childDict["education"] as? String
                        
                        //location
                        self.locationField.text = childDict["location"] as? String ?? "Cityville"
                        
                        //name
                        self.nameField.text = childDict["name"] as? String ?? "Mr. Incredible"
                        
                        //work
                        self.workField.text = childDict["work"] as? String ?? "Superhero Inc."
                        
                        
                        //profile image
                        if let pictureURL = childDict["picture"] as? String {
                            let filePath = "\(id)/\("userPhoto")"
                            self.storageRef.child(filePath).data(withMaxSize: 10*1024*1024, completion: { (data, error) in
                                if (error != nil) {
                                    print(error ?? "image pull failed")
                                    self.getProfilePicture()
                                }
                                else {
                                    let userPhoto = UIImage(data: data!)
                                    self.profileView.image = userPhoto
                                    print("pulled profile pic locally")
                                }
                            })
                        }
                    }
                }
                self.queryFB(flag: existsInDB)
            })
        }
        else {
            print("id key doesn't exist")
            
            queryFB(flag: false)
        }
    }
    
    
    public func addToFriendNewsFeed(event: String, ownID: String){
        for friend in friendsArray{
            let idString = String(friend.id!)
            
            ref.child("newsfeed").child(idString).observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                   
                let newsfeed = snapshot.value as? NSArray
                
                var updatedFeed = newsfeed?.adding([event, NSDate().timeIntervalSince1970, ownID ])
                
                if updatedFeed == nil{
                    print("Creating feed for ", friend.name)
                    updatedFeed = [ [event, NSDate().timeIntervalSince1970], ownID ]
                }
                self.ref.child("newsfeed").child(idString).setValue(updatedFeed)
                    // ...
                }) { (error) in
                    print(error.localizedDescription)
                }
            
        }
    }
    
    /**
     Sent to the delegate when the app invite completes without error.
     - Parameter appInviteDialog: The FBSDKAppInviteDialog that completed.
     - Parameter results: The results from the dialog.  This may be nil or empty.
     */
    public func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable : Any]!){
        print("Complete invite without error")
    }
    
    
    /**
     Sent to the delegate when the app invite encounters an error.
     - Parameter appInviteDialog: The FBSDKAppInviteDialog that completed.
     - Parameter error: The error.
     */
    public func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!){
        print("Error in invite \(error)")
    }
    
    public func didFailAutocompleteWithError(_ error: Error) {
    }
    
    /**
     * Called when autocomplete predictions are available.
     * @param predictions an array of GMSAutocompletePrediction objects.
     */
    public func didAutocomplete(with predictions: [GMSAutocompletePrediction]) {
        
        for prediction in predictions {
            
            if let prediction = prediction as GMSAutocompletePrediction!{
                self.resultsArray.append(prediction.attributedFullText.string)
            }
        }
        self.searchResultController.reloadDataWithArray(self.resultsArray)
        print(resultsArray)
    }

}
