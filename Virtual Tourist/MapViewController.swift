//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Sam Black on 3/22/22.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var pin: Pin!
    var pinLong:Double = 0.0
    var pinLat:Double = 0.0
    var editMode = false
    

    // https://stackoverflow.com/questions/34431459/ios-swift-how-to-add-pinpoint-to-map-on-touch-and-get-detailed-address-of-th
    // https://stackoverflow.com/questions/28058082/swift-long-press-gesture-recognizer-detect-taps-and-long-press
    // https://knowledge.udacity.com/questions/313110
    override func viewDidLoad() {
        super.viewDidLoad()
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //dataController = appDelegate.dataController
        // Allow for long press to add pins in below lines
        dataController = DataController(modelName: "VirtualTourist")
        dataController.load()
        let gestureRecognizer = UILongPressGestureRecognizer(
                                      target: self, action:#selector(addPinOnLongPress(gestureRecognizer:)))
            gestureRecognizer.delegate = self
            mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        retrievePinsFromCore()
        mapView.delegate = self

    }


    var annotations = [MKPointAnnotation]()

    @objc func addPinOnLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        let latitude = CLLocationDegrees(coordinate.latitude)
        let longitude = CLLocationDegrees(coordinate.longitude)
        // Add annotation:
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        annotations.append(annotation)
        addPinToCoreData(lat: latitude, long: longitude)
        setupFetchedResultsController(lat: latitude, long: longitude)
        try? dataController.viewContext.save()

    }
    
    func addPinToCoreData(lat:Double, long:Double){
        
        pin = Pin(context: dataController.viewContext)
        pin.createDate = Date()
        pin.lat = lat
        pin.long = long
        try? dataController.viewContext.save()
        print("Saved pin to core data")
    }
    
    // Deletes the `Pin` at the specified index path
    func deletePin(at indexPath: IndexPath) {
        let pinToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(pinToDelete)
        try? dataController.viewContext.save()
    }
    
    
    fileprivate func retrievePinsFromCore() {
        // create fetchRequest
        print("Running retrievePinsFromCore")
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            // if there are persisted PIN core data
            if let count = fetchedResultsController.fetchedObjects?.count, count > 0 {
                print("pin count > 0")
                // TODO: Set PIN to the map
                for pin in fetchedResultsController.fetchedObjects! {
                    let location = CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.long)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = location
                    mapView.addAnnotation(annotation)
                }
            }
        } catch {
            fatalError("Error when try to fetch the album \(error.localizedDescription)")
        }
        
    }
    
    
    
    // Adapt Mooskine code to take lat/long
    func setupFetchedResultsController(lat: Double, long: Double) {
        
        
        print("Pin: setup fetch result controller!")
        //fetchedResultsController = nil
        // create fetchRequest
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        // TODO: Need to  update the predicate
        print("predicate is \(lat) and \(long)")
        // https://knowledge.udacity.com/questions/40768 for lat/long conversions
        let latNSNumber:NSNumber = NSNumber.init(value: lat)
        let longNSNumber:NSNumber = NSNumber.init(value: long)
        // Since Latitude and longitude are both Double values, we need to use NSNumbers instead. Can't use %@ with this type
        let predicateLatitude = NSPredicate(format: "lat == %@", latNSNumber)
        let predicateLongtitude = NSPredicate(format: "long == %@", longNSNumber)
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [predicateLatitude, predicateLongtitude])
        fetchRequest.predicate = andPredicate
        let sortDescriptor = NSSortDescriptor(key: "createDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            // if no data object is fetched, then persists the Pin
            // Create variable count and set = to count stored in fetchedObjects
            // If 0, add Pin to core data
            print("Print Fetched Object:")
            print("--------------------------------------------")
            //print(fetchedResultsController.fetchedObjects!.data.lat)
            print("--------------------------------------------")
            //print(fetchedResultsController.fetchedObjects!.long)
            print("--------------------------------------------")
            //print(pin.long)
            print("--------------------------------------------")
            print(fetchedResultsController.fetchedObjects!)
            print("--------------------------------------------")
            print("Print Count:")
            print(fetchedResultsController.fetchedObjects!.count)
            if let count = fetchedResultsController.fetchedObjects?.count, count == 0 {
                // let's create an new pin
                print("Add new pin")
                addPinToCoreData(lat: lat, long: long)
            }
            // if pin already exists.....
            else {
                print("we found existing pin")
                let existingPins:[Pin] = fetchedResultsController.fetchedObjects!
                pin = existingPins[0]
                print("we found existing pin with created date: \(String(describing: pin.createDate!))")
            }
        } catch {
            fatalError("Error when try to fetch the album \(error.localizedDescription)")
        }
    }
    
    // https://stackoverflow.com/questions/37247220/how-can-i-perform-an-action-when-i-tap-on-a-pin-from-mapkit-ios9-swift-2
    private func mapView(_ mapView: MKMapView!, didSelect view: MKAnnotationView!)
    {
        // https://knowledge.udacity.com/questions/477492
        let photoVC: PhotoAlbumViewController = storyboard?.instantiateViewController(identifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
               photoVC.dataController = self.dataController
               
        let chosenPin = Pin(context: dataController.viewContext)
        pinLong = (view.annotation!.coordinate.longitude)
        pinLat = (view.annotation!.coordinate.latitude)
        print("pinLat:***********")
        print(pinLat)
        photoVC.dataController = self.dataController
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            // if there are persisted PIN core data
            if let count = fetchedResultsController.fetchedObjects?.count, count > 0 {
                print("pin count > 0")
                // TODO: Set PIN to the map
                var counter: Int = 0
                let pins = fetchedResultsController.fetchedObjects!
                for _ in pins {
                    counter += 1
                    // if selected Pin coordinates match coordinates of pin in core data
                    // Set indexpth equal to first pin instance where lat and long = lat and long of selected pin
                    // https://knowledge.udacity.com/questions/56235
                    guard let indexPath = pins.firstIndex(where: { (pin) -> Bool in
                        pinLat == pin.lat && pinLong == pin.long })
                    else {
                        return
                    }
                        //let indexPath = IndexPath(row: 0, section: 0)
                        // Make that the selected pin in the PhotoAlbum VC
                        print("SUCCESSFULLY MATCHED PIN TO NEXT VC")
                        //photoVC.pin = fetchedResultsController.object(at: IndexPath)
                        photoVC.pin = pins[indexPath]
                        photoVC.dataController = dataController
                    print(photoVC.pin.lat)
                    print(photoVC.pin.long)
                    print("----------------")

                    }
                }
            } catch {
            fatalError("Error when try to fetch the album \(error.localizedDescription)")
        }

        
        //photoVC.pin = fetchedResultsController.object(at: IndexPath)

         print("PIN did select with lat \(pinLat) and long \(pinLong)")
             //  When a pin is tapped, the app will navigate to the Photo Album view associated with the pin.
             // fetch the tapped pin from Core Data again
        setupFetchedResultsController(lat: pinLat, long: pinLong)
        performSegue(withIdentifier: "mapToAlbum", sender: self)
        try! dataController.viewContext.save()
         }
    
}

