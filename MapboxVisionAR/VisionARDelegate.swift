//
//  VisionARDelegate.swift
//  MapboxVisionAR
//
//  Created by Maksim on 3/15/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation

public protocol VisionARDelegate: class {
    func visionARManager(visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera)
    func visionARManager(visionARManager: VisionARManager, didUpdateARLane lane: ARLane?)
}

public extension VisionARDelegate {
    func visionARManager(visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera) { }
    func visionARManager(visionARManager: VisionARManager, didUpdateARLane lane: ARLane?) { }
}
