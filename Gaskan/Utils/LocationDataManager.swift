//
//  LocationDataManager.swift
//  Gaskan
//
//  Created by Dzulfikar on 12/04/23.
//

import Foundation
import CoreLocation
import BackgroundTasks
import CoreData

class LocationDataManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = LocationDataManager()
    var locationManager = CLLocationManager()
    
    @Published var isLocationTrackingEnabled: Bool = false
    @Published var isLocationAccessPermitted: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var location: CLLocation?
    @Published var isDriving: Bool = false
    
    private var traveledDistance: Double = 0
    private var lastLocation: CLLocation!
    private var drivingStateTimer: Timer?
    private var trackingTimer: Timer?
    
    override init() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = true
        
        super.init()
        locationManager.delegate = self
        startSpeedCheck()
        handleDistanceTracking()
        
    }
    
    func enable() {
        locationManager.startUpdatingLocation()
    }
    
    func disable() {
        locationManager.stopUpdatingLocation()
    }
    
    func startSpeedCheck() {
        // if drivingStateTimer is not set, create new one.
        if drivingStateTimer === nil {
            drivingStateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [self] timer in
                if (Double(String(self.location?.speed.description ?? "0")) ?? 0 > 4.16667) {
                    self.isDriving = true
                } else {
                    self.isDriving = false
                }
            }
        }
    }
    
    func stopSpeedCheck() {
        drivingStateTimer?.invalidate()
    }
    
    func handleDistanceTracking() {
        Timer.scheduledTimer(withTimeInterval: 3000, repeats: true) { timer in
            if !self.isDriving {
                if self.traveledDistance > 0 {
                    // reset data
                    print(self.traveledDistance)
                    let persistentContainer = PersistenceController.shared.container
                    let context = persistentContainer.newBackgroundContext()
                    context.automaticallyMergesChangesFromParent = true
                    context.perform {
                        // handle empty data.
                        let items: NSFetchRequest<Item> = Item.fetchRequest()
                        items.predicate = NSPredicate(format: "type == %@", CalculationType.newCalculation.rawValue)
                        do {
                            let hasCalculation = try context.fetch(items)
                            if !hasCalculation.isEmpty {
                                let newItem = Item(context: context)
                                newItem.id = UUID()
                                newItem.type = CalculationType.newTrip.rawValue
                                newItem.timestamp = Date()
                                newItem.totalMileage = hasCalculation[0].unit == UnitData.metricOption.value ? Float(self.traveledDistance / 1000) : Float(self.traveledDistance / 0.000621371)
                                newItem.fuelEfficiency = 0.0
                                newItem.totalFuelCost = 0.0
                                
                                print("[NewTripScreenView][addItem]")
                                try context.save()
                                self.traveledDistance = 0
                            }
                        } catch {
                            print(String(describing: error.localizedDescription))
                        }
                    }
                }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:  // Location services are available.
            authorizationStatus = .authorizedWhenInUse
            locationManager.requestLocation()
            enable()
            break
            
        case .authorizedAlways:
            authorizationStatus = .authorizedAlways
            locationManager.requestLocation()
            enable()
            break
            
        case .restricted:  // Location services currently unavailable.
            // Insert code here of what should happen when Location services are NOT authorized
            authorizationStatus = .restricted
            disable()
            break
            
        case .denied:  // Location services currently unavailable.
            // Insert code here of what should happen when Location services are NOT authorized
            authorizationStatus = .denied
            disable()
            break
            
        case .notDetermined:        // Authorization not determined yet.
            authorizationStatus = .notDetermined
            locationManager.requestWhenInUseAuthorization()
            break
            
        default:
            break
        }
    }
    
    func getCalculationType(type: String) -> CalculationType {
        switch type {
        case CalculationType.newTrip.rawValue:
            return .newTrip
        case CalculationType.refuel.rawValue:
            return .refuel
        case CalculationType.newCalculation.rawValue:
            return .newCalculation
        default:
            return .newCalculation
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Insert code to handle location updates
        if let currentLocation = locations.first {
            print(currentLocation)
            location = currentLocation
        }
        
        // handle distance traveled
        if isDriving {
            if lastLocation != nil {
                traveledDistance += lastLocation.distance(from: locations.last!)
            }
            lastLocation = locations.last
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error.localizedDescription)")
    }
}
