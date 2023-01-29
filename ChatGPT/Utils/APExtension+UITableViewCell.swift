//
//  APExtension+UITableViewCell.swift
//  eZen Dev
//
//  Created by Wykee on 19/12/2022.
//  Copyright © 2022 Music of Wisdom. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension UITableViewCell {
    public static var identifier: String {
        return String(describing: self)
    }
}

extension NSManagedObject {
    public static var identifier: String {
        return String(describing: self)
    }
}
