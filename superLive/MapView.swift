//
//  MapView.swift
//  superLive
//
//  Created by Alexis Ponce on 11/12/21.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    var locationManager = CLLocationManager()
    @ObservedObject var mapModel : MapModel
    func makeUIView(context: Context) -> some  MKMapView{
        let mapView = MKMapView()
        mapModel.copyOfMapView = mapView
        mapView.delegate = context.coordinator
        locationManager.delegate = context.coordinator
        locationManager.requestAlwaysAuthorization()
        switch locationManager.authorizationStatus{// checks the tracking status
        case .denied:// if user denied we will show a message asking the user to allow
            print("The use denied the use of location services for the app or they are disabled globally in Settings");
            break;
        case.restricted://
            print(" The app is not authorized to use location services");
            break;
        case .authorizedAlways:
            print("ViewController: [322] The user authorized the app o use location services");
            break
        case .authorizedWhenInUse:
            print("ViewController: [325] the user authorized the app to start location services while it is in use");
            break;
        case .notDetermined:// neither accepted or denied location access to the app
            print(" User has not determined whether the app can use location services");
            print("The use denied the use of location services for the app or they are disabled globally in Settings");
            break;
        default:
            break;
        }
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters// sets the accuracy of the location services
        self.locationManager.startUpdatingLocation()
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate{
        var parent : MapView
        
        init(_ parent: MapView){
            self.parent = parent
        }
        var globalLocationCoordinates = [CLLocationCoordinate2D]()
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            let location = locations[0]
            
            parent.mapModel.centerLocation(location: location.coordinate)
        }
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline{
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = .red
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
    
}

class MapModel: ObservableObject{
    @Published var globalLocationCoordinates = [CLLocationCoordinate2D]()
    @Published var copyOfMapView : MKMapView!
    var previousAnnotation = MKPointAnnotation()
    var workoutStarted = false
    var isFirstLocationToTrack = true
    private var firstLocation: CLLocation!
    private var secondLocation: CLLocation!
    @Published var workoutDistance = 0.0;
    func centerLocation(location: CLLocationCoordinate2D){
        print("The workout state is \(workoutStarted)")
        if workoutStarted{
            globalLocationCoordinates.append(location)
            let polyline = MKPolyline(coordinates: globalLocationCoordinates, count: globalLocationCoordinates.count)
            self.copyOfMapView.addOverlay(polyline)
            if isFirstLocationToTrack{
                firstLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                isFirstLocationToTrack = false
                
            }else{
                secondLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                workoutDistance += secondLocation.distance(from: firstLocation)
                firstLocation = secondLocation
            }

        }else{
            isFirstLocationToTrack = true
            workoutDistance = 0.0
            let coordinatePin = MKPointAnnotation()
            coordinatePin.coordinate = location
            self.copyOfMapView.removeAnnotation(previousAnnotation)
            previousAnnotation = coordinatePin
            self.copyOfMapView.addAnnotation(coordinatePin)
        }
        let coordSpan = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let coordRegion = MKCoordinateRegion(center: location, span: coordSpan)
        self.copyOfMapView.setRegion(coordRegion, animated: true)
        print("The workout distnance is \(workoutDistance)")
        
        
    }
    
    func getDistance()->Double{
        return workoutDistance
    }
    
    func calculateDistanceWithWorkout(){
        
    }
    
    func calculateDistanceWithoutWorkout(){
        
    }
}
