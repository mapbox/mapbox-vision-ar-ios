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

public final class VisionARManager: VisionARDelegateNative {
    
    private var native: VisionARManagerNative?
    private let delegate: VisionARDelegate
    
    public static func create(visionManager: VisionManager, delegate: VisionARDelegate) -> VisionARManager {
        let mananger = VisionARManager(delegate)
        mananger.native = VisionARManagerNative.create(withVisionManager: visionManager.native, delegate: mananger)
        return mananger
    }
    
    private init(_ delegate: VisionARDelegate) {
        self.delegate = delegate
    }
    
    public func setRoute(_ route: Route) {
        guard let native = native else {
            assertionFailure()
            return
        }
        native.setRoute(route)
    }
    
    public func destroy() {
        guard let native = native else {
            assertionFailure()
            return
        }
        native.destroy()
    }
    
    public func onARCameraUpdated(_ camera: ARCamera) {
        delegate.visionARManager(visionARManager: self, didUpdateARCamera: camera)
    }
    
    public func onARLaneUpdated(_ lane: ARLane?) {
        delegate.visionARManager(visionARManager: self, didUpdateARLane: lane)
    }
}
