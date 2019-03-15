//
//  VisionSafetyDelegate.swift
//  MapboxVisionSafety
//
//  Created by Maksim on 3/15/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation

public protocol VisionSafetyDelegate: class {
    func onRoadRestrictionsUpdated(manager: VisionSafetyManager, roadRestrictions: RoadRestrictions)
    func onCollisionsUpdated(manager: VisionSafetyManager, collisions: [CollisionObject])
}
    
public extension VisionSafetyDelegate {
    func onRoadRestrictionsUpdated(manager: VisionSafetyManager, roadRestrictions: RoadRestrictions) { }
    func onCollisionsUpdated(manager: VisionSafetyManager, collisions: [CollisionObject]) { }
}

