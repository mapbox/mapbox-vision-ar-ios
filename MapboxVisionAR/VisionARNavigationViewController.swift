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
    private var renderer: ARRenderer?
    private var navigationManager: NavigationManager?
    
    /**
    Create an instance of VisionARNavigationController by specifying route controller from MapboxCoreNavigation framework.
    */
    
    public init(navigationService: NavigationService? = nil) {
        
        super.init(nibName: nil, bundle: nil)
        
        self.navigationService = navigationService
        setNavigationService(navigationService)
        
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
        super.init(coder: aDecoder)
    }
    
    /**
        NavigationService from MapboxCoreNavigation framework
    */
    
    public var navigationService: NavigationService? {
        didSet {
            setNavigationService(navigationService)
        }
    }
    
    private func setNavigationService(_ navigationService: NavigationService?) {
        if let navigationService = navigationService {
            navigationManager = NavigationManager(navigationService: navigationService)
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
        addChildView(arView)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visionManager.start()
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard visionManager.delegate == nil else { return }
        visionManager.stop()
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
        view.preferredFramesPerSecond = 30
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
