//
//  VisionARDelegate.swift
//  MapboxVisionAR
//
//  Created by Maksim on 3/15/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation

public protocol VisionARDelegate: class {
    func onARCameraUpdated(visionARManager: VisionARManager, camera: ARCamera)
    func onARLaneUpdated(visionARManager: VisionARManager, lane: ARLane?)
}

public extension VisionARDelegate {
    func onARCameraUpdated(visionARManager: VisionARManager, camera: ARCamera) { }
    func onARLaneUpdated(visionARManager: VisionARManager, lane: ARLane?) { }
}
