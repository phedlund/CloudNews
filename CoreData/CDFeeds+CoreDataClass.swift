//
//  CDFeeds+CoreDataClass.swift
//  CloudNews
//
//  Created by Peter Hedlund on 10/31/18.
//  Copyright © 2018 Peter Hedlund. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CDFeeds)
public class CDFeeds: NSManagedObject {

    static private let entityName = "CDFeeds"

    static func update(starredCount: Int, newestItemId: Int) {
        NewsData.mainThreadContext.performAndWait {
            let request: NSFetchRequest<CDFeeds> = CDFeeds.fetchRequest()
            do {
                let records = try NewsData.mainThreadContext.fetch(request)
                if let existingRecord = records.first {
                    existingRecord.newestItemId = Int32(newestItemId)
                    existingRecord.starredCount = Int32(starredCount)
                } else {
                    let newRecord = NSEntityDescription.insertNewObject(forEntityName: CDFeeds.entityName, into: NewsData.mainThreadContext) as! CDFeeds
                    newRecord.newestItemId = Int32(newestItemId)
                    newRecord.starredCount = Int32(starredCount)
                }
                
                try NewsData.mainThreadContext.save()
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
    }
    
}