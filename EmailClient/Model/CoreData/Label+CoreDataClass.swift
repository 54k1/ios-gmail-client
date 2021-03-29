//
//  Label+CoreDataClass.swift
//  EmailClient
//
//  Created by SV on 27/03/21.
//
//

import CoreData
import Foundation

@objc(Label)
public class LabelMO: NSManagedObject {}

extension LabelMO {
    func configure(with label: GMailAPIService.Resource.Label) {
        id = label.id
        name = label.name
    }
}
