//
//  NavigationProvider.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 3/22/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxCoreNavigation
import MapboxVision

protocol NavigationManagerDelegate: class {
    func navigationManager(_ navigationManager: NavigationManager, didUpdate route: NavigationRoute)
    func navigationManagerArrivedAtDestination(_ navigationManager: NavigationManager)
}

final class NavigationManager {
    weak var delegate: NavigationManagerDelegate? {
        didSet {
            delegate?.navigationManager(self, didUpdate: NavigationRoute(route: routeController.routeProgress.route))
        }
    }
    
    private let routeController: RouteController
    private var routeHasChanged = true
    
    init(routeController: RouteController) {
        self.routeController = routeController
        
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange), name: .routeControllerProgressDidChange, object: routeController)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute), name: .routeControllerDidReroute, object: routeController)
    }
    
    @objc private func progressDidChange(_ notification: NSNotification) {
        guard let routeProgress = notification.userInfo?[RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress else { return }
        
        if routeHasChanged {
            routeHasChanged = false
            delegate?.navigationManager(self, didUpdate: NavigationRoute(route: routeProgress.route))
        }
        
        if routeProgress.currentLegProgress.userHasArrivedAtWaypoint {
            routeHasChanged = true
            delegate?.navigationManagerArrivedAtDestination(self)
        }
    }
    
    @objc private func didReroute(_ notification: NSNotification) {
        routeHasChanged = true
    }
}
