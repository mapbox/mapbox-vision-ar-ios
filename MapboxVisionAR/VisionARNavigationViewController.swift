//
// Created by Alexander Pristavko on 8/21/18.
// Copyright (c) 2018 Mapbox. All rights reserved.
//

import Foundation
import UIKit
import MetalKit
import MapboxVision
import MapboxCoreNavigation

/**
    Protocol that defines a set of methods that are called by VisionARNavigationViewController to notify about AR navigation events.
*/

public protocol VisionARNavigationViewControllerDelegate: class {
    
    /**
        Receive location of next next maneuver
    */
    
    func visionARNavigationViewController(_ viewController: VisionARNavigationViewController, didUpdateManeuverLocation locationInView: CGPoint?)
}

/**
 Class that represents visual component that renders video stream from the camera and AR navigation route on top of that. It may be presented in a host application in a typical for the platform way.
 
 `VisionARNavigationController` creates, manages and exposes for external usage an instance of `VisionManager` .
*/

public class VisionARNavigationViewController: UIViewController {
    
    /**
        The delegate object to receive AR events.
    */
    
    public weak var delegate: VisionARNavigationViewControllerDelegate?
    
    private let visionManager = VisionManager.shared
    private let visionViewController: VisionPresentationViewController
    private var renderer: ARRenderer?
    private var navigationManager: NavigationManager?
    
    /**
    Create an instance of VisionARNavigationController by specifying route controller from MapboxCoreNavigation framework.
    */
    
    public init(routeController: RouteController? = nil) {
        visionViewController = visionManager.createPresentation()
        
        super.init(nibName: nil, bundle: nil)
        
        self.routeController = routeController
        setRouteController(routeController)
        
        visionManager.arDelegate = self
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            assertionFailure("Can't create Metal device")
            return
        }
        
        arView.device = device
        
        do {
            try renderer = ARRenderer(device: device,
                                      dataProvider: visionManager,
                                      colorPixelFormat: arView.colorPixelFormat,
                                      depthStencilPixelFormat: arView.depthStencilPixelFormat)
            renderer?.initScene()
            arView.delegate = renderer
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    /**
     :nodoc:
    */
    
    required public init?(coder aDecoder: NSCoder) {
        visionViewController = visionManager.createPresentation()
        super.init(coder: aDecoder)
    }
    
    /**
        Route controller from MapboxCoreNavigation framework
    */
    
    public var routeController: RouteController? {
        didSet {
            setRouteController(routeController)
        }
    }
    
    private func setRouteController(_ routeController: RouteController?) {
        if let routeController = routeController {
            navigationManager = NavigationManager(routeController: routeController)
            navigationManager?.delegate = self
        } else {
            navigationManager = nil
        }
    }
    
    /**
     :nodoc:
    */
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        visionViewController.willMove(toParentViewController: self)
        addChildViewController(visionViewController)
        visionViewController.didMove(toParentViewController: self)
        
        addChildView(visionViewController.view)
        addChildView(arView)
    }
    
    private func addChildView(_ childView: UIView) {
        childView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childView)
        
        NSLayoutConstraint.activate([
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    private let arView: MTKView = {
        let view = MTKView()
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.framebufferOnly = false
        view.autoResizeDrawable = true
        view.contentMode = .scaleAspectFill
        view.preferredFramesPerSecond = 20
        view.isOpaque = false
        return view
    }()
}

extension VisionARNavigationViewController: NavigationManagerDelegate {
    
    func navigationManager(_ navigationManager: NavigationManager, didUpdate route: NavigationRoute) {
        visionManager.startNavigation(to: route)
    }
    
    func navigationManagerArrivedAtDestination(_ navigationManager: NavigationManager) {
        visionManager.stopNavigation()
    }
}

extension VisionARNavigationViewController: VisionManagerARDelegate {
    
    /**
     :nodoc:
    */
    
    public func visionManager(_ visionManager: VisionManager, didUpdateManeuverLocation maneuverLocation: ManeuverLocation?) {
        guard let maneuver = maneuverLocation else {
            delegate?.visionARNavigationViewController(self, didUpdateManeuverLocation: nil)
            return
        }
        
        let worldPosition = WorldCoordinate(
            x: Double(maneuver.origin.x),
            y: Double(maneuver.origin.y),
            z: 0
        )
        
        let framePixel = visionManager.worldToPixel(worldCoordinate: worldPosition)
        
        let locationInView = framePixel.convertForAspectRatioFill(
            from: visionManager.frameSize,
            to: view.bounds.size
        )
        
        delegate?.visionARNavigationViewController(self, didUpdateManeuverLocation: locationInView)
    }
}
