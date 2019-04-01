//
//  ViewController.swift
//  VisionARSample
//
//  Copyright © 2019 Mapbox. All rights reserved.
//

import UIKit
import MapboxVision
import MapboxVisionAR
import MapboxDirections
import MapboxCoreNavigation

class ViewController: UIViewController, VisionManagerDelegate {
    
    let camera = CameraVideoSource()
    let visionARViewController = VisionARViewController()
    
    var visionManager: VisionManager!
    var visionARManager: VisionARManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(visionARViewController)
        view.addSubview(visionARViewController.view)

        visionManager = VisionManager.create(videoSource: camera)
        visionARManager = VisionARManager.create(visionManager: visionManager, delegate: self)
        
        camera.add(observer: self)
        visionManager.start(delegate: self)
        camera.start()
        
        let directions = Directions(accessToken: nil)
        let origin = CLLocationCoordinate2D()
        let destination = CLLocationCoordinate2D()
        let options = NavigationRouteOptions(coordinates: [origin, destination], profileIdentifier: .automobile)
        directions.calculate(options) { [unowned self] (_, routes, error) in
            guard error == nil, let route = routes?.first else { return }
            self.visionARManager.setRoute(Route(route: route))
        }
    }
}

extension ViewController: VideoSourceObserver {
    
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        DispatchQueue.main.async { [unowned self] in
            guard let frame = CMSampleBufferGetImageBuffer(videoSample.buffer) else { return }
            self.visionARViewController.present(frame: frame)
        }
    }
}

extension ViewController: VisionARDelegate {
    
    func visionARManager(visionARManager: VisionARManager, didUpdateARLane lane: ARLane?) {
        DispatchQueue.main.async { [unowned self] in
            self.visionARViewController.present(lane: lane)
        }
    }
    
    func visionARManager(visionARManager: VisionARManager, didUpdateARCamera camera: ARCamera) {
        DispatchQueue.main.async { [unowned self] in
            self.visionARViewController.present(camera: camera)
        }
    }
}

