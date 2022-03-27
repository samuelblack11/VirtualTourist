//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Sam Black on 3/26/22.
//
//

import Foundation
import CoreData

//https://www.hackingwithswift.com/books/ios-swiftui/one-to-many-relationships-with-core-data-swiftui-and-fetchrequest

extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var photo: Data?
    @NSManaged public var pin: Pin?
    
   // public var photoArray: [Photo] {
   //     let set = photo as? Set<Photo> ?? []
   //     return set
   // }

}

extension Photo : Identifiable {

}
