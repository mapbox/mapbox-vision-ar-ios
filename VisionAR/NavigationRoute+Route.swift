//
//  NavigationRoute.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 3/29/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections
import VisionCore

extension NavigationRoute {
    convenience init(route: Route) {
        self.init()
        
        var coordinates = Array<RoutePoint>()
        
        route.legs.forEach { $0.steps.forEach { step in
            
            let maneuver = RoutePoint(
                lat: step.maneuverLocation.latitude,
                lon: step.maneuverLocation.longitude,
                isManeuver: true,
                maneuverName: step.maneuverDirection.description,
                streetName: step.names?.first ?? ""
            )
            coordinates.append(maneuver)
            
            guard let coords = step.coordinates else { return }
            let routePoints = coords.map {
                RoutePoint(
                    lat: $0.latitude,
                    lon: $0.longitude,
                    isManeuver: false,
                    maneuverName: step.maneuverDirection.description,
                    streetName: step.names?.first ?? ""
                )
            }
            coordinates.append(contentsOf: routePoints)
        } }
        
        self.coordinates = coordinates
    }
}
