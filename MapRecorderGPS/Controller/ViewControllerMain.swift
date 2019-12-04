//
//  ViewController.swift
//  MapRecorderGPS
//
//  Created by Wolf on 03/12/2019.
//  Copyright © 2019 WolfMobileApp. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewControllerMain: UIViewController {

    
    //views outlets:
    @IBOutlet weak var textViewDetails: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonStartStopOutlet: UIButton!
    
    // user defaults
    let defaults = UserDefaults.standard
    
    // zmienna do location Managera
     let locationManager = CLLocationManager()
    
    // dane wyjściowe z location Managera
    var locationCurrent: CLLocationCoordinate2D? // aktualna lokalizacja która nie będzie nil po pierwszej odpowiedzi z GPS
    var locationsList: [CLLocationCoordinate2D] = [] // lista punktów na mapie
    var totalLenghtInMeters: Int = 0 // obliczenie odległości w metrach
    var intervalTimeInSec: Int = 0 // obliczenie przedziału czasowego w sekundach
    var intervalTimeString = "00:00:00" // obliczenie przedziału czasowego w stringu do View
    var speedInKmPerH: Double = 0.0 //obliczenie średniej prędkości w km/h
    var dateTime = Date() // aktualna data - zmienia na aktualniejszą przy każdym zapisie trasy

    // context służy do zapisu, odczytu i innych z Core Data. Odnosi się do contenera DataModel z AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    // czas włączenia
    var startTime: TimeInterval?
    
    // dodanie znacznika
    let annotation = MKPointAnnotation()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // do location
        locationManager.requestAlwaysAuthorization() // pozwolenie na to żeby dziłało location - działa też z background
        locationManager.delegate = self // dodanie delegata
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation //najwyrzsza dokładność lokalizacji
        locationManager.allowsBackgroundLocationUpdates = true //jdziała w background
        locationManager.startUpdatingLocation() // startuje i pobiera cały czas lokalizację delegat musi być dodany przed tym
        
        //do Map
        mapView.delegate = self // dodanie delegata żeby wyświeltlać polyline
        
        // ustawienie ikonki play lub stop w zależności od defaults
        if defaults.bool(forKey: C.boolForStartStop) == false {
            buttonStartStopOutlet.setBackgroundImage(UIImage(imageLiteralResourceName: "start_button_transparent"), for: .normal) // ustawienie ikonki na play
        } else {
            buttonStartStopOutlet.setBackgroundImage(UIImage(imageLiteralResourceName: "stop_button_transparent"), for: .normal) // ustawienie ikonki na stop
        }
    }
    
    // button Start/Stop
    @IBAction func buttonPlayStop(_ sender: UIButton) {
        
        // włączenie
        if defaults.bool(forKey: C.boolForStartStop) == false { // WYłączony

            // funkcja do włączenia nagrywania
            startRecording()
            
        // wyłączenie
        }else { // Włączony
            
            // funkcja do wYłączenia nagrywania
            stopRecordning ()
        }
    }
    
    // button Roads - do następnego activity
    @IBAction func buttonRoads(_ sender: UIButton) {
        
        // otworzenie drugiego okna
        performSegue(withIdentifier: "IDSegueRoads", sender: self)
    }
    
    // funkcja do włączenia nagrywania
    func startRecording () {
                    
        // ustawienie bool na włączony
        defaults.set(true, forKey: C.boolForStartStop)
        
        // ustawienie ikonki na stop
        buttonStartStopOutlet.setBackgroundImage(UIImage(imageLiteralResourceName: "stop_button_transparent"), for: .normal)
        
        // wyczyszczenie listy do zera
        if locationsList.count != 0 {
            locationsList.removeAll()
        }
        
        // wyczyszczenie odległości
        totalLenghtInMeters = 0
        
        // dodanie ostatniej pozycji z menagera jeśli juz się włączył
        if let locationCurrentUnwrapped = locationCurrent {
            locationsList.append(locationCurrentUnwrapped)
        }
        
        // zapisanie aktualnego czasu
        startTime = Date().timeIntervalSince1970
        print(startTime!)
    }
    
    // funkcja do wYłączenia nagrywania
    func stopRecordning () {
                    
        // ustawienie bool na wyłączony
        defaults.set(false, forKey: C.boolForStartStop)
        
        // ustawienie ikonki na play
        buttonStartStopOutlet.setBackgroundImage(UIImage(imageLiteralResourceName: "start_button_transparent"), for: .normal)
        
        // pobranie czasu wyłączenia i obliczenie przedziału czasowego
        dateTime = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.timeStyle = DateFormatter.Style.none
//        dateFormatter.dateStyle = DateFormatter.Style.short
//        let date = dateFormatter.string(from: dateTime) // 12/15/16
//        print("date: \(date)")
        let stopTime = Date().timeIntervalSince1970
        intervalTimeInSec = Int(stopTime - startTime!)
        print("intervalTimeInSec: \(intervalTimeInSec)")
        // przeliczenie na format 00:00:00
        let hours = (intervalTimeInSec) / 3600
        let minutes = (intervalTimeInSec / 60) - Int(hours * 60)
        let seconds = (intervalTimeInSec) - (Int(intervalTimeInSec / 60) * 60)
        intervalTimeString = String(NSString(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds))
        
        // obliczeni prędkości
        let speedInMeterPerSec: Double = Double(totalLenghtInMeters) / Double(intervalTimeInSec)
        print("speedInMeterPerSec: \(speedInMeterPerSec)")
        speedInKmPerH = (round((speedInMeterPerSec * 3.6)*10)) / 10 // wynik w km/h zaokrąglony do 0.0
        print("speedInKmPerH: \(speedInKmPerH)")
        
        //zapisanie danych w Core Data
        SaveRoadInCoreData ()
    }
    
    //zapisanie danych w Core Data
    func SaveRoadInCoreData () {
        
        // zapisanie nowego elementu Road do Core Data
        let newRoad = Road(context: self.context) //stworznie nowego obiektu NSManagedObject
        newRoad.nameOfListWithRoadPoints = String(Date().timeIntervalSince1970) // niepowtażalna nazwa listy (nie lista) z map points czli [RoadPoint]
        newRoad.totalLenghtInMeters = Int64(totalLenghtInMeters) // odpakowanie to Int(totalLenghtInMeters)
        newRoad.intervalTimeInSec = Int64(intervalTimeInSec)
        newRoad.intervalTimeString = intervalTimeString
        newRoad.speedInKmPerH = speedInKmPerH
        newRoad.dateTime = dateTime // to jest Date()
        saveToCoreData() // zapisanie aktualnego stanu tablicy context do Core Data
        
        // pobranie aktualnej tablicy [Road] żeby przypisać do ostatniego jej elementu wszystkie z [RoadPoint]
        let request : NSFetchRequest<Road> = Road.fetchRequest()
        var listOfRoads: [Road] = []
        do {
            listOfRoads = try context.fetch(request)
        }catch {
            print("Error fetching data from context: \(error)")
            return // jak będczie error to nie zapisze elementów na mapie jak niżej
        }
        
        // zmiana tablicy locationsList: [CLLocationCoordinate2D] na tablicę listOfRoadPoints: [RoadPoint] żeby zapisać do Core Data wszystkie lementy
        var listOfRoadPoints: [RoadPoint] = []
        for item in locationsList {
            let lat = Double(item.latitude) // zmiana danej na double
            let lon = Double(item.longitude) // zmiana danej na double
            let roadPoint = RoadPoint(context: self.context)
            roadPoint.lat = lat
            roadPoint.lon = lon
            roadPoint.parentCategory = listOfRoads[listOfRoads.count-1] // parentCategory to nazwa poołączenia między bazami Entity
            listOfRoadPoints.append(roadPoint) // dodanie do tablicy
        }
        saveToCoreData() // zapisanie aktualnego stanu tablicy
    }
    
    // zapisanie zmian w CoreData
    func saveToCoreData() {
        do {
            try context.save()
        }catch{
            print("Error Saving Context: \(error)")
        }
    }

    
}




// MARK: - localization funcjons
extension ViewControllerMain: CLLocationManagerDelegate, MKMapViewDelegate{
    
    // funkcja wywoływana przez delegata bedzie automatycznie się updatowała przy zmianie lokalizacji.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       
        if let location = locations.last{ //last czyli ostatni element z listy bo na liście mogą być zapisane wcześniejsze położenia
        
            // pobranie aktualnej pozycji
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            let setLocationCurrent = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            // zapisanie aktualnej lokalizacji do zmiennej globalnej żeby użyć przy starcie zapisu
            locationCurrent = setLocationCurrent
            
            // ustawienie kamery na zapisany region
            let span = MKCoordinateSpan(latitudeDelta: C.heightOfCameraOnMap, longitudeDelta: C.heightOfCameraOnMap) // ustawienie wysokości kamery
            let region = MKCoordinateRegion(center: setLocationCurrent, span: span)
            mapView.setRegion(region, animated: true)
            
            // dodanie znacznika
            annotation.coordinate = setLocationCurrent
            //annotation.title = "You Are \nHERE"
            //annotation.subtitle = "London"
            mapView.addAnnotation(annotation)
            
            // jeśli jest kliknięte Play to dodaje to listy i robi polyline
            if defaults.bool(forKey: C.boolForStartStop){
                
                // dodanie aktualnej pozycji do listy
                locationsList.append(setLocationCurrent)
                
                // dodanie polyline na Map
                let aPolyline = MKPolyline(coordinates: locationsList, count: locationsList.count) // zapisanie polyline do stałej
                mapView.addOverlay(aPolyline) // ustawienie poliline na mapach
                
                // obliczeni odległości
                if locationsList.count > 1{
                    let start = locationsList[locationsList.count - 2]
                    let end = locationsList[locationsList.count - 1]
                    let distance = getDistance(from: start, to: end) // funkcja do pbliczania dystansu zwraca w metrach
                    totalLenghtInMeters += Int(distance)
                }
                
                print("totalLenghtInMeters \(totalLenghtInMeters) m")
            }
        
        }
    }
    
    // funkcja do obliczania dystansu
    func getDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        // By Aviel Gross
        // https://stackoverflow.com/questions/11077425/finding-distance-between-cllocationcoordinate2d-points
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)
    }
    
    //funkcja będzie wywoływana gdy nie zdobedzie lokalizcji
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    // funkcja do ustawienia polilini
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer! {
        if overlay is MKPolyline {
            let polylineRender = MKPolylineRenderer(overlay: overlay)
            polylineRender.strokeColor = UIColor.red.withAlphaComponent(0.5)
            polylineRender.lineWidth = 5
            return polylineRender
        }
        return nil
    }
}


