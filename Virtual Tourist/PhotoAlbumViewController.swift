//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Sam Black on 3/23/22.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var newCollectionButton: UIButton!
    

    @IBOutlet weak var collectionView: UICollectionView!
    var isDataSaved: Bool = false
    var flickrPhotos: [PhotoResponse] = []
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var fetchedPinResultsController: NSFetchedResultsController<Pin>!
    var dataController:DataController!
    var isNewCollectionPressed: Bool = false

    let placeholder:String = "photoPlaceHolder"
    let removeButtonLabel = "Remove Selected Pictures"
    let defaultButtonLabel = "New Collection"
    var pin: Pin!
    var photo: Photo!
    var per_page:Int=30
    var removePhotos:[IndexPath] = []
    var isRemoveMode:Bool = false
    //var fetchResultController:NSFetchedResultsController<Photo>!
    @IBOutlet weak var photoViewCell: ImageCell?
    
    fileprivate func retrievePinsFromCore() {
        // create fetchRequest

        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedPinResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedPinResultsController.delegate = self
        do {
            try fetchedPinResultsController.performFetch()
            // if there are persisted PIN core data
            if let count = fetchedPinResultsController.fetchedObjects?.count, count > 0 {

                // TODO: Set PIN to the map
                for pin in fetchedPinResultsController.fetchedObjects! {
                    let location = CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.long)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = location
                }
            }
        } catch {
            fatalError("Error when try to fetch the album \(error.localizedDescription)")
        }
        
    }
    
    
    
    override func viewDidLoad() {
    super.viewDidLoad()
    dataController = DataController(modelName: "VirtualTourist")
    dataController.load()
    //PhotoAPI.getPhotos(lat: 25.7617, long: 80.1918, page: 1, perPage: self.flickrPhotos.count, completionHandler: {
    retrievePinsFromCore()
    //print(Pin)
    print("configure fetch results controller:")
    configureFetchResultsController()
    print("---------")
    //print("Get Photos:")
    configureCollectionView()
    newCollectionButton.isEnabled = true
        
    }
    
    func configureFetchResultsController(){
        //create fetch request
        //sort descriptor, predicate and attach them to fetch results controller
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "photo", ascending: false)
        //let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [sortDescriptor]
        //fetchRequest.predicate = predicate
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch() // fetch results
            print("Successful Fetch in configureFetchResultsController")
        }catch{
            fatalError("Failed to load data from memory")
        }
        //if number of fetched results >0 then we have data saved else download it
        let results = fetchedResultsController.fetchedObjects!
        if results.count > 0 {
            isDataSaved = true
            self.newCollectionButton.isEnabled = true
        }else{
            isDataSaved = false
            self.newCollectionButton.isEnabled = false
        }
    }
    
    
    
    func configureCollectionView(){
        //configure UI
        collectionView.delegate = self
        collectionView.dataSource = self
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let width = UIScreen.main.bounds.width
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: width / 4, height: width / 5)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView!.collectionViewLayout = layout
    }
    
    
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
         super.viewDidDisappear(animated)
         fetchedResultsController = nil
     }
    

    
    func loadPhoto(indexPath: IndexPath)->Photo?{
        //get photo object at index
        return fetchedResultsController.object(at: indexPath)
    }
    
    func savePhoto(image: UIImage){
        //save photo object to memory
        let photo = Photo(context: dataController.viewContext)
        photo.photo = image.pngData() as NSObject? as? Data
        photo.pin = pin
        do{
            try dataController.viewContext.save()
        }catch{
            fatalError(error.localizedDescription)
        }
    }
    
    func deletePhoto(indexPath: IndexPath){
        //delete photo from memory
        let photo = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photo)
        do{
            try dataController.viewContext.save()
        }catch{
            fatalError(error.localizedDescription)
        }
        configureFetchResultsController()
    }
    
    @IBAction func newCollectionPressed(_ sender:Any){
        //fetch new set of images
        //get random page number
        self.newCollectionButton.isEnabled = false
        let page = PhotoAPI.getRandomPage()
        print("Page")
        print(page)

        PhotoAPI.getPhotos(lat: pin.lat, long: pin.long, page: page, perPage: self.flickrPhotos.count, completionHandler: {
            (responses, error) in
            /*check if responses not nill set them in collection view class, delete existing images and
             save new images
            */
            if let responses = responses{
                print("responses=responses")
                self.flickrPhotos = responses
                self.isDataSaved = false
                self.isNewCollectionPressed = true
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        })
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isDataSaved{
            return fetchedResultsController.sections![section].numberOfObjects
        }else{
            return self.flickrPhotos.count
        }    }
    
    @objc func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //populate cells
        // https://www.hackingwithswift.com/example-code/uikit/how-to-register-a-cell-for-uicollectionview-reuse
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "photoViewCell")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoViewCell", for: indexPath) as! ImageCell
        print(cell)
        
        print("cellForItemAt********")
        //check if there are images load them if not then download images
        if isDataSaved{
            self.newCollectionButton.isEnabled = true
            //populate cells with them
            let pic = loadPhoto(indexPath: indexPath)
            let imgData = pic!.photo
            let img = UIImage(data: imgData!)
            cell.imageView.image = img
        }else{
            print("PlaceHolder")
            cell.imageView.image = UIImage(named: "placeholder")
            print("IndexPath:")
            print(indexPath)
            print("Cell:")
            print(cell)
            downloadImagesAndReload(indexPath: indexPath, cell: cell)
            }
        return cell
    }


    
    @nonobjc func numberOfSections(in collectionView: UICollectionView) -> Int {
        if isDataSaved{
            return fetchedResultsController.sections!.count
        }else{
            return 1
        }
    }
    
    @nonobjc func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //delete image
        collectionView.deleteItems(at: [indexPath])
        deletePhoto(indexPath: indexPath)
        //reload table
        DispatchQueue.main.async {
            collectionView.reloadData()
        }
    }
    
    func downloadImagesAndReload(indexPath: IndexPath, cell: ImageCell){
        //download them
        print("Attempting Download")
        PhotoAPI.getImageAt(index: indexPath.row, response: self.flickrPhotos, completionHandler: {
            (img, error) in
            if let img = img {
                cell.imageView.image = img
                //save it to memory
                self.savePhoto(image: img)
                //check if it's new collection then delete next image in memory
                if(indexPath.row < self.fetchedResultsController.fetchedObjects!.count - 1){
                    //if it's not last photo
                    if(self.isNewCollectionPressed){
                        print("isNewCollectionPressed")
                        let newIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                        self.deletePhoto(indexPath: newIndex)
                    }
                }
                else{
                    //last photo need to change boolean
                    print("isNewCollectionPressed false")
                    self.isNewCollectionPressed = false
                    self.isDataSaved = true
                    self.configureFetchResultsController() //reload fetch results controller
                    self.collectionView.reloadData()
                }
            }
        })
    }
}

