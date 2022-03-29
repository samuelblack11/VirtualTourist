//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Sam Black on 3/23/22.
//

import Foundation
import CoreData

class DataController {

    // https://knowledge.udacity.com/questions/285614
    static let shared = DataController()
    
    let persistenceContainer:NSPersistentContainer

    

    var viewContext:NSManagedObjectContext {
        return persistenceContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext!

    init() {
        persistenceContainer = NSPersistentContainer(name: "VirtualTourist")
        backgroundContext = persistenceContainer.newBackgroundContext()
    }
    
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        
        persistenceContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()
            self.configureContexts()
            completion?()
        }
    }

}

extension DataController {
    
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("autosaving")
        
        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }
        
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
