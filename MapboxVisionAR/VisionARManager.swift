//
//  VisionARManager.swift
//  MapboxVisionAR
//
//  Created by Maksim on 3/13/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore
import MapboxVisionARCore
import MapboxVision

public final class VisionARManager {
    
    private var native: VisionARManagerNative?
    private var delegate: VisionARDelegate?
    
    public static func create(visionManager: VisionManager, delegate: VisionARDelegate? = nil) -> VisionARManager {
        let manager = VisionARManager()
        manager.native = VisionARManagerNative.create(withVisionManager: visionManager.native, delegate: manager)
        manager.delegate = delegate
        return manager
    }
    
    public func destroy() {
        native?.destroy()
        native = nil
        delegate = nil
    }
    
    public func set(route: Route) {
        native?.setRoute(route)
    }
}

extension VisionARManager: VisionARDelegateNative {
    public func onARCameraUpdated(_ camera: ARCamera) {
        delegate?.visionARManager(visionARManager: self, didUpdateARCamera: camera)
    }
    
    public func onARLaneUpdated(_ lane: ARLane?) {
        delegate?.visionARManager(visionARManager: self, didUpdateARLane: lane)
    }
}
