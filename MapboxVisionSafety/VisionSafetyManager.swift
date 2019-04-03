//
//  VisionSafetyManager.swift
//  MapboxVisionSafety
//
//  Created by Maksim on 3/15/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import MapboxVision
import MapboxVisionSafetyCore

public final class VisionSafetyManager {
    
    private var native: VisionSafetyManagerNative?
    private var delegate: VisionSafetyDelegate?
    
    public static func create(visionManager: VisionManager, delegate: VisionSafetyDelegate? = nil) -> VisionSafetyManager {
        let manager = VisionSafetyManager()
        manager.native = VisionSafetyManagerNative.create(visionManager: visionManager.native, delegate: manager)
        manager.delegate = delegate
        return manager
    }
    
    public func destroy() {
        assert(native != nil, "VisionSafetyManager has alreaady been destroyed")
        native?.destroy()
        native = nil
        delegate = nil
    }
    
    public func setCarCollisionSensitivity(warningTime: Float, criticalTime: Float) {
        native?.setCarCollisionSensitivity(warningTime, criticalTime: criticalTime)
    }
    
    public func setMinSpeedToAlertCar(minSpeed: Float) {
        native?.setMinSpeedToAlertCar(minSpeed)
    }
    
    public func setMinSpeedToAlertPerson(minSpeed: Float) {
        native?.setMinSpeedToAlertPerson(minSpeed)
    }
}

extension VisionSafetyManager: VisionSafetyDelegateNative {
    public func onRoadRestrictionsUpdated(_ roadRestrictions: RoadRestrictions) {
        delegate?.onRoadRestrictionsUpdated(manager: self, roadRestrictions: roadRestrictions)
    }
    
    public func onCollisionsUpdated(_ collisions: [CollisionObject]) {
        delegate?.onCollisionsUpdated(manager: self, collisions: collisions)
    }
}
