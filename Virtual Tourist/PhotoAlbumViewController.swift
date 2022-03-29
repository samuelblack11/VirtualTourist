//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Sam Black on 3/23/22.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {

    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    var isDataSaved: Bool = false
    var flickrPhotos: [PhotoResponse] = []
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var fetchedPinResultsController: NSFetchedResultsController<Pin>!
    var isNewCollectionPressed: Bool = false
    let placeholder:String = "photoPlaceHolder"
    var pin: Pin!
    var photo: Photo!
    @IBOutlet weak var photoViewCell: ImageCell?
    
    fileprivate func retrievePinsFromCore() {
        // Fetch Pin, sort by create date
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedPinResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedPinResultsController.delegate = self
        do {
            try fetchedPinResultsController.performFetch()
            // if # of pins > 0
            if let count = fetchedPinResultsController.fetchedObjects?.count, count > 0 {
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
    retrievePinsFromCore()
    print("configure fetch results controller:")
    configureFetchResultsController()
    configureCollectionView()
    newCollectionButton.isEnabled = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        configureFetchResultsController()
    }
    
    func configureFetchResultsController(){
        // Fetch photos, predicated on the associated pin (based on lat and long)
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "photo", ascending: false)
        // https://knowledge.udacity.com/questions/676104
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("Failed to load data from memory")
        }
        let results = fetchedResultsController.fetchedObjects!
        if results.count > 0 {
            isDataSaved = true
            self.newCollectionButton.isEnabled = true
            
        }else{
            PhotoAPI.getPhotos(lat: pin.lat, long: pin.long, page: 1, perPage: self.flickrPhotos.count, completionHandler: {
                (responses, error) in
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
            isDataSaved = false
            self.newCollectionButton.isEnabled = false
        }
    }
    
    
    
    func configureCollectionView(){
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
        return fetchedResultsController.object(at: indexPath)
    }
    
    func savePhoto(image: UIImage){
        let photo = Photo(context: DataController.shared.viewContext)
        photo.photo = image.pngData() as NSObject? as? Data
        photo.pin = pin
        do{
            try DataController.shared.viewContext.save()
        }catch{
            fatalError(error.localizedDescription)
        }
    }
    
    //https://www.hackingwithswift.com/example-code/uikit/how-to-find-a-touchs-location-in-a-view-with-locationin
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: collectionView)
            print(position)
        }
    }
    
    
    @objc func deletePhoto(indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        DataController.shared.viewContext.delete(photo)
        do{
            try DataController.shared.viewContext.save()
        }catch{
            fatalError(error.localizedDescription)
        }
        configureFetchResultsController()
    }
    
    @IBAction func newCollectionPressed(_ sender:Any){
        // Fetch new images from Flickr
        self.newCollectionButton.isEnabled = false
        PhotoAPI.getPhotos(lat: pin.lat, long: pin.long, page: 1, perPage: self.flickrPhotos.count, completionHandler: {
            (responses, error) in
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoViewCell", for: indexPath) as! ImageCell
        print("cellForItemAt********")
        if isDataSaved{
            self.newCollectionButton.isEnabled = true
            // Load photos to the cells
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
        collectionView.deleteItems(at: [indexPath])
        deletePhoto(indexPath: indexPath)
        DispatchQueue.main.async {
            collectionView.reloadData()
        }
    }
    
    func downloadImagesAndReload(indexPath: IndexPath, cell: ImageCell){
        print("Attempting Download")
        PhotoAPI.getImageAt(index: indexPath.row, response: self.flickrPhotos, completionHandler: {
            (img, error) in
            if let img = img {
                cell.imageView.image = img
                self.savePhoto(image: img)
                if(indexPath.row < self.fetchedResultsController.fetchedObjects!.count - 1){
                    if(self.isNewCollectionPressed){
                        print("isNewCollectionPressed")
                        let newIndex = IndexPath(row: indexPath.row + 1, section: indexPath.section)
                        self.deletePhoto(indexPath: newIndex)
                    }
                }
                else{
                    print("isNewCollectionPressed false")
                    self.isNewCollectionPressed = false
                    self.isDataSaved = true
                    self.configureFetchResultsController()
                    self.collectionView.reloadData()
                }
            }
        })
    }
}

