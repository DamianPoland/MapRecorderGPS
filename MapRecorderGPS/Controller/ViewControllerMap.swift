//
//  ViewControllerMap.swift
//  MapRecorderGPS
//
//  Created by Wolf on 04/12/2019.
//  Copyright © 2019 WolfMobileApp. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewControllerMap: UIViewController, MKMapViewDelegate {
    
    //views
    @IBOutlet weak var viewMap: MKMapView!
    
    // context służy do zapisu, odczytu i innych z Core Data. Odnosi się do contenera DataModel z AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // zmienna przekazana z popredniego widoku
    var nameOfListWithRoadPoints:String = ""
    
    // element listOfRoads przekazany z poprzedniego widoku po to żeby wyświetlić listę MapPaint która jest znim powiązana w Core Data
    var selectedCategory: Road? 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //do Map
        viewMap.delegate = self // dodanie delegata żeby wyświeltlać polyline
        

        //pobiera listę MapPoint z danej tablicy
        loadItems()

    }
    
    //pobranie wszystkich elementów tablicy [RoadPoint] z Core Data i dodanie do tablicy var itemArray: [Item] = [] stworzonej wcześniej
    func loadItems () {
        let request : NSFetchRequest<RoadPoint> = RoadPoint.fetchRequest()
        
        // ustawienie filtra żeby wczytywał tylko punkty z [MapPoints] przypisane do niepowtarzalnej nazwy z obiektu [Road]
        let predicate = NSPredicate(format: "parentCategory.nameOfListWithRoadPoints MATCHES %@", selectedCategory!.nameOfListWithRoadPoints!)
        request.predicate = predicate
        
        do {
            //pobranie listy z Core Data
            let listOfRoadPoints = try context.fetch(request)
            let listOfRoadPointsSorted = listOfRoadPoints.sorted(by: { $0.order > $1.order }) // posortowana tabelka bo Core Data zapisuje nie po kolei gdzie order to wartość z podrzędnej klasy zapisana po kolei w Int - czyli 1 2 3 ....
            
            // zabezpieczenie przed pustą listą
            if listOfRoadPointsSorted.count < 1 {
                print("list of points in Core Data is empty")
                return
            }
            
            // przekształcenie listy punktów [RoadPoint] na CLLocationCoordinate2D
            var locationsList: [CLLocationCoordinate2D] = []
            for item in listOfRoadPointsSorted {
                
                let lat = item.lat
                let lon = item.lon
                let setLocationCurrent = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                locationsList.append(setLocationCurrent)
            }
            
            // dodanie polyline na Map
            let aPolyline = MKPolyline(coordinates: locationsList, count: locationsList.count) // zapisanie polyline do stałej
            viewMap.addOverlay(aPolyline) // ustawienie poliline na mapach
            
            // ustawienie kamery na zapisany region
            let span = MKCoordinateSpan(latitudeDelta: C.heightOfCameraOnMap, longitudeDelta: C.heightOfCameraOnMap) // ustawienie wysokości kamery
            let region = MKCoordinateRegion(center: locationsList.last!, span: span)
            viewMap.setRegion(region, animated: true)
            
        }catch {
            print("Error fetching data from context: \(error)")
        }
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
