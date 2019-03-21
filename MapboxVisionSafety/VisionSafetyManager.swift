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

public final class VisionSafetyManager: VisionSafetyDelegateNative {
    
    private var native: VisionSafetyManagerNative?
    private let delegate: VisionSafetyDelegate
    
    public static func create(visionManager: VisionManager, delegate: VisionSafetyDelegate) -> VisionSafetyManager {
        let mananger = VisionSafetyManager(delegate)
        mananger.native = VisionSafetyManagerNative.create(withVisionManager: visionManager.native, delegate: mananger)
        return mananger
    }
    
    private init(_ delegate: VisionSafetyDelegate) {
        self.delegate = delegate
    }
    
    public func destroy() {
        guard let native = native else {
            assertionFailure()
            return
        }
        native.destroy()
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
    
    public func onRoadRestrictionsUpdated(_ roadRestrictions: RoadRestrictions) {
        delegate.onRoadRestrictionsUpdated(manager: self, roadRestrictions: roadRestrictions)
    }
    
    public func onCollisionsUpdated(_ collisions: [CollisionObject]) {
        delegate.onCollisionsUpdated(manager: self, collisions: collisions)
    }
}
