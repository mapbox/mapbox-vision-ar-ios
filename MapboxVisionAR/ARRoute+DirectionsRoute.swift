//
//  ARRoute+DirectionsRoute.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 3/29/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections
import MapboxVisionARCore

extension MapboxVisionARCore.Route {
    convenience init(route: MapboxDirections.Route) {
        var points = Array<RoutePoint>()
        
        route.legs.forEach { $0.steps.forEach { step in
            
            let maneuver = RoutePoint(
                position: GeoCoordinate(lon: step.maneuverLocation.longitude, lat: step.maneuverLocation.latitude),
                maneuver: .unknown
            )
            points.append(maneuver)
            
            guard let coords = step.coordinates else { return }
            let routePoints = coords.map {
                RoutePoint(
                    position: GeoCoordinate(lon: $0.longitude, lat: $0.latitude),
                    maneuver: .unknown
                )
            }
            points.append(contentsOf: routePoints)
        } }
        
        self.init(points: points,
                  eta: Float(route.expectedTravelTime),
                  sourceStreetName: route.legs.first?.source.name ?? "",
                  destinationStreetName: route.legs.last?.destination.name ?? "")
    }
}
