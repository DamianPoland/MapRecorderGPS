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
import GoogleMobileAds

class ViewControllerMain: UIViewController, GADBannerViewDelegate {

    
    //views outlets:
    @IBOutlet weak var viewTime: UILabel!
    @IBOutlet weak var viewDist: UILabel!
    @IBOutlet weak var viewSpeed: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonStartStopOutlet: UIButton!
    @IBOutlet weak var viewSwitchFocus: UISwitch!
    
    // user defaults
    let defaults = UserDefaults.standard
    
    // zmienna do location Managera
     let locationManager = CLLocationManager()
    
    // dane wyjściowe z location Managera
    var locationCurrent: CLLocationCoordinate2D? // aktualna lokalizacja która nie będzie nil po pierwszej odpowiedzi z GPS
    var locationsList: [CLLocationCoordinate2D] = [] // lista punktów na mapie
    var totalLenghtInMeters: Int = 0 // Core 1. obliczenie odległości w metrach
    var intervalTimeInSec: Int = 0 // Core 2. obliczenie przedziału czasowego w sekundach
    var intervalTimeString = C.viewTimeDefault // Core 3. obliczenie przedziału czasowego w stringu do View - default to "00:00:00 s"
    var speedInKmPerH: Double = 0.0 //Core 4. obliczenie średniej prędkości w km/h
    // dateTime - Core 5. aktualna data - nie trzerba deklarować - dodane w SaveRoadInCoreData()
    //nameOfListWithRoadPoints - Core 6. - nie trzerba deklarować - dodane w SaveRoadInCoreData() - po tej zmiennej jest sortowanie w ViewControllerMap

    // context służy do zapisu, odczytu i innych z Core Data. Odnosi się do contenera DataModel z AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    // czas włączenia
    var startTime: TimeInterval?
    
    // dodanie znacznika
    let annotation = MKPointAnnotation()
    
    // timer stoper
    var timer = Timer()
    var counter = 0
    
    // do usuwania starych polylines z mapy - tu się zapisują wszystkie polylines co są na mapie
    var oldPolyLines: [MKPolyline] = []

    // do reklam bannera
    var bannerView: GADBannerView!
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // do location
        locationManager.requestAlwaysAuthorization() // pozwolenie na to żeby dziłało location - działa też z background
        locationManager.delegate = self // dodanie delegata
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters//najwyrzsza dokładność lokalizacji
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
        
        // przywrócenie wartości zapisywanych do Core Data na domyślne zerowe - msi być po SaveRoadInCoreData()
        doVariablesAsDefault()
        
        // przywrócenie wartości wyświetlanych na domyślne zerowe
        doViewsAsDefaults()
        
        // ustawienie switcha Focus w zależności od userDefaults
        if defaults.bool(forKey: C.keyToSwitchFocusOnOff) {
            viewSwitchFocus.setOn(true, animated: true)
        } else {
            viewSwitchFocus.setOn(false, animated: true)
        }
        
        // do reklam banner
        bannerView = GADBannerView(adSize: kGADAdSizeBanner) // utworzeni bannera
        //addBannerViewToView(bannerView) // wywołanie funkcji z utworzeniem bannera w danym view - zrobione w funkcji adViewDidReceiveAd
        bannerView.adUnitID = "ca-app-pub-1490567689734833/7184364377" // to jest przykłądowy i zmienić na bannerID
        bannerView.rootViewController = self
        bannerView.load(GADRequest()) // wczytanie reklamy
        bannerView.delegate = self // dodanie delegata z dziedziczenia GADBannerViewDelegate żeby wywołać funkcję np adViewDidReceiveAd

    }
    
    // funkcja pochodzi z protokołu GADBannerViewDelegate
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
      addBannerViewToView(bannerView) // wywołanie funkcji z utworzeniem bannera w danym view
    }
    
    // jeśli zmieni się jednośtki w ustawieniach na US lub EU i wróci do ViewControllerMain. i będzie na zero wszystko to przeładuje widoki żeby zmienic jednostki
    override func viewWillAppear(_ animated: Bool) {
        if viewTime.text == C.viewTimeDefault {
            doViewsAsDefaults()
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
    
    // button Info otwiera vievControllerInfo
    @IBAction func buttonInfo(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "IDSegueInfo", sender: self)
    }
    
    // button do otwietania settings
    @IBAction func buttonSettings(_ sender: Any) {
        performSegue(withIdentifier: "IDSegueSettings", sender: self)
    }
    
    
    // button do ustawiania czy mabyć auto-focus czy nie
    @IBAction func buttonSwitchFocus(_ sender: UISwitch) {
        if viewSwitchFocus.isOn {
            defaults.set(true, forKey: C.keyToSwitchFocusOnOff)
        } else {
            defaults.set(false, forKey: C.keyToSwitchFocusOnOff)
        }
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
        
        // usuwa wszystkie polylines co są na mapie
        if self.oldPolyLines.count > 0 {
            for polyline in oldPolyLines {
                mapView.removeOverlay(polyline)
            }
        }
        
        // zapisanie aktualnego czasu
        startTime = Date().timeIntervalSince1970
        
        // włączenie pokazywania czasu
        counter = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (Timer) in // ustawienie na sekundowe włączanie i updatowanie view co sekunde
            self.counter += 1
            self.viewTime.text = self.changeTimeInSecOnHourMinuteSec(timeInSec: self.counter) // przeliczenie sekund na format 00:00:00 s
            //print(self.changeTimeInSecOnHourMinuteSec(timeInSec: self.counter))
        })
            
    }
    
    // funkcja do wYłączenia nagrywania
    func stopRecordning () {
                    
        // ustawienie bool na wyłączony
        defaults.set(false, forKey: C.boolForStartStop)
        
        // ustawienie ikonki na play
        buttonStartStopOutlet.setBackgroundImage(UIImage(imageLiteralResourceName: "start_button_transparent"), for: .normal)
        
        // wyłączenie timera
        timer.invalidate()
        
        //zapisanie danych w Core Data - musi być przed doViewsAndVariablesAsDefault()
        SaveRoadInCoreData ()
        
        // przywrócenie wartości zapisywanych do Core Data na domyślne zerowe - msi być po SaveRoadInCoreData()
        doVariablesAsDefault()
        
        // przywrócenie wartości wyświetlanych na domyślne zerowe
        doViewsAsDefaults()
        
        // toast do poinformowania że droga zostałą zapisana
        showToast(controller: self, message: "Road saved in My Roads", seconds: 1.5)
        

    }
    
    //zapisanie danych w Core Data
    func SaveRoadInCoreData () {
        
        // Core 2. obliczenie przedziału czasowego w sekundach
        let stopTime = Date().timeIntervalSince1970 // ilość sekund od 1970 do teraz
        intervalTimeInSec = Int(stopTime - startTime!) // Core 2. obliczenie przedziału czasowego w sekundach
        
        // Core 3. obliczenie sekund na format 00:00:00 s, updatowanie view z time jest z Timera
        intervalTimeString = changeTimeInSecOnHourMinuteSec(timeInSec: intervalTimeInSec)
        
        // zapisanie nowego elementu Road do Core Data
        let newRoad = Road(context: self.context) //stworznie nowego obiektu NSManagedObject
        newRoad.totalLenghtInMeters = Int64(totalLenghtInMeters) // Core 1. odpakowanie to Int(totalLenghtInMeters)
        newRoad.intervalTimeInSec = Int64(intervalTimeInSec) // Core 2.
        newRoad.intervalTimeString = intervalTimeString // Core 3.
        newRoad.speedInKmPerH = speedInKmPerH // Core 4.
        newRoad.dateTime = Date() // Core 5.  to jest aktualna data 
        newRoad.nameOfListWithRoadPoints = String(Date().timeIntervalSince1970) // Core 6. niepowtażalna nazwa listy (nie lista) z map points czli [RoadPoint]
        saveToCoreData() // zapisanie aktualnego stanu tablicy [Road] do Core Data
        
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
        DispatchQueue.global(qos: .background).async {
            var listOfRoadPoints: [RoadPoint] = []
            var order = 1
            for item in self.locationsList {
                let lat = Double(item.latitude) // zmiana danej na double
                let lon = Double(item.longitude) // zmiana danej na double
                let roadPoint = RoadPoint(context: self.context)
                roadPoint.lat = lat
                roadPoint.lon = lon
                roadPoint.order = Int64(order) // przypisanie wartości żeby potem mozna było elementy ustawić po kolei bo Core Data nie zapisuje po kolei
                order += 1 // podniesienie o jeden kolejności
                roadPoint.parentCategory = listOfRoads[listOfRoads.count-1] // parentCategory to nazwa poołączenia między bazami Entity
                listOfRoadPoints.append(roadPoint) // dodanie do tablicy
            }
            self.saveToCoreData() // zapisanie aktualnego stanu tablicy [RoadPoint]
        }

    
    }
    
    // zapisanie zmian w CoreData
    func saveToCoreData() {
        do {
            try context.save()
        }catch{
            print("Error Saving Context: \(error)")
        }
    }
    
    //  przywrócenie wartości zapisywanych do Core Data na domyślne zerowe
    func doVariablesAsDefault() {
        totalLenghtInMeters = 0
        intervalTimeInSec = 0
        intervalTimeString = C.viewTimeDefault
        speedInKmPerH = 0.0
    }
    
    // przywrócenie wartości wyświetlanych na domyślne zerowe
    func doViewsAsDefaults() {
        viewTime.text = C.viewTimeDefault
        
        if defaults.bool(forKey: C.keyToSwitchUnitsOnOff) { // jeśli amerykański jednostki są ustawione
            viewDist.text = C.viewDistDefaultUS
        } else {
            viewDist.text = C.viewDistDefault
        }
        
        if defaults.bool(forKey: C.keyToSwitchUnitsOnOff) { // jeśli amerykański jednostki są ustawione
            viewSpeed.text = C.viewSpeedDefaultUS
        } else {
        viewSpeed.text = C.viewSpeedDefault
        }
    }
    
    // przeliczenie sekund na format 00:00:00 s
    func changeTimeInSecOnHourMinuteSec(timeInSec: Int) -> String {
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        let formattedString = formatter.string(from: TimeInterval(timeInSec))!
        return formattedString + " s"
    }

    // toast do poinformowania że droga zostałą zapisana
    func showToast(controller: UIViewController, message: String, seconds: Double) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = UIColor.black
        alert.view.alpha = 0.8
        alert.view.layer.cornerRadius = 15
        controller.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)        }
    }
    
    // funkcja do stworzenia View z bannerem czyli GADBannerView
    func addBannerViewToView(_ bannerView: GADBannerView) {
      bannerView.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(bannerView)
      view.addConstraints(
        [NSLayoutConstraint(item: bannerView,
                            attribute: .bottom,
                            relatedBy: .equal,
                            toItem: bottomLayoutGuide, //nie zmieniać tego!
                            attribute: .top,
                            multiplier: 1,
                            constant: 0),
         NSLayoutConstraint(item: bannerView,
                            attribute: .centerX,
                            relatedBy: .equal,
                            toItem: view,
                            attribute: .centerX,
                            multiplier: 1,
                            constant: 0)
        ])
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

            // ustawienie kamery na zapisany region tylko jeśli jest włączony buttonSwitchFocus
            if defaults.bool(forKey: C.keyToSwitchFocusOnOff) {
                let span = MKCoordinateSpan(latitudeDelta: C.heightOfCameraOnMap, longitudeDelta: C.heightOfCameraOnMap) // ustawienie wysokości kamery
                let region = MKCoordinateRegion(center: setLocationCurrent, span: span)
                mapView.setRegion(region, animated: true)
            }

            // dodanie znacznika
            annotation.coordinate = setLocationCurrent
            //annotation.title = "You Are \nHERE"
            //annotation.subtitle = "London"
            mapView.addAnnotation(annotation)
            
            // jeśli jest kliknięte Play to:
            if defaults.bool(forKey: C.boolForStartStop){
                
                // dodanie aktualnej pozycji do listy
                locationsList.append(setLocationCurrent)
                
                // tworzy polyline i dodaje do mapy
                let aPolyline = MKPolyline(coordinates: locationsList, count: locationsList.count)
                mapView.addOverlay(aPolyline) // ustawienie poliline na mapach
                
                // dodaje stworzoną polyline do tablicy żeby potem można było usunąc wszystkie z tablicy w button Play
                oldPolyLines.append(aPolyline)

                // jesśli jest włączone nagrywanie i są >=2 mapPointy
                if locationsList.count > 1{
                    
                    // Core 1. obliczenie odległości w metrach i pokaznie w view
                    let start = locationsList[locationsList.count - 2]
                    let end = locationsList[locationsList.count - 1]
                    let distance = getDistance(from: start, to: end) // funkcja do policzania dystansu zwraca w metrach
                    totalLenghtInMeters += Int(distance) // Core 1. obliczenie odległości w metrach
                    if defaults.bool(forKey: C.keyToSwitchUnitsOnOff) { // jeśli amerykański jednostki są ustawione
                        let metersToMiles = (round(Double(totalLenghtInMeters) * 0.0006213712*1000))/1000 // przeliczenie na mile jeśli są ustawione jednostki US
                        viewDist.text = String(metersToMiles) + " miles" //updatowanie view z dystansem
                    } else {
                        viewDist.text = String(totalLenghtInMeters) + " m" //updatowanie view z dystansem
                    }
                    
                    // Core 4. obliczenie średniej prędkości w km/h i pokazanie w view prędkości
                    let stopTimeToView = Date().timeIntervalSince1970 // ilość sekund od 1970 do teraz
                    let intervalTimeInSec = Int(stopTimeToView - startTime!) // obliczenie ile sekund trwała trasa
                    if intervalTimeInSec > 0 && totalLenghtInMeters > 0 { // zabezpieczeni żeby nie było zer
                        let speedInMeterPerSec: Double = Double(totalLenghtInMeters) / Double(intervalTimeInSec)
                        speedInKmPerH = (round((speedInMeterPerSec * 3.6)*10)) / 10 // Core 4. obliczenie średniej prędkości w km/h zaokrąglony do 0.0
                        if defaults.bool(forKey: C.keyToSwitchUnitsOnOff) { // jeśli amerykański jednostki są ustawione
                            let metersToMiles = (round(speedInKmPerH * 0.62*100))/100 // przeliczenie na mile jeśli są ustawione jednostki US
                            viewSpeed.text = String(metersToMiles) + " miles/h"
                        } else {
                            viewSpeed.text = String(speedInKmPerH) + " km/h"
                        }
                    }
                }
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


