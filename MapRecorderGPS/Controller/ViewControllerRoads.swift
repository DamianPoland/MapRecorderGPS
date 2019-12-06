//
//  ViewControllerRoads.swift
//  MapRecorderGPS
//
//  Created by Wolf on 03/12/2019.
//  Copyright © 2019 WolfMobileApp. All rights reserved.
//

import UIKit
import CoreData

class ViewControllerRoads: UIViewController {
    

    //views outlets:
    @IBOutlet weak var tableView: UITableView!
    
    // context służy do zapisu, odczytu i innych z Core Data. Odnosi się do contenera DataModel z AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // stworzenie listy Roads
    var listOfRoads: [Road] = []
    
    // user defaults
    let defaults = UserDefaults.standard
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        //pobranie wszystkich elementów tablicy [Road] z Core Data i dodanie do tablicy listOfRoads
        loadFromCoreData ()
    }
    
    //pobranie wszystkich elementów tablicy [Road] z Core Data i dodanie do tablicy listOfRoads
    func loadFromCoreData () {
        let request : NSFetchRequest<Road> = Road.fetchRequest()
        do {
            let listOfRoadsNotSorted = try context.fetch(request)
            listOfRoads = listOfRoadsNotSorted .sorted(by: { $0.dateTime! > $1.dateTime! }) // posortowanie tableki wg daty
        }catch {
            print("Error fetching data from context: \(error)")
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
}

//MARK: - do table View
// dodać Extension do ViewControler czyli  zrobić w tym samym oknie co jest tableView ale poza klasą ViewControler
extension ViewControllerRoads: UITableViewDelegate, UITableViewDataSource{
    
    // funkcja do zapisania ile będzie rzędów w tableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfRoads.count // tyle rzędów ile w tabeli elementów
    }
    
    //funkcja zwraca dane w każdej komórce
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        //dane: withIdentifier to ID dodane do Cell, po as? to klasa powiązana z Cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "IDCell") as! TableViewCell
    
        // ustawienie dnia
        let dateFromCoreData = listOfRoads[indexPath.row].dateTime!
        let formatter = DateFormatter()
        let day = formatter.weekdaySymbols[Calendar.current.component(.weekday, from: Date())]
        cell.viewDay.text = day
        
        //ustawienie daty
        formatter.dateFormat = "dd-MM-yyyy"
        let date = formatter.string(from: dateFromCoreData)
        cell.viewDate.text = date
        
        //ustawienie czasu drogi
        let time = String(listOfRoads[indexPath.row].intervalTimeString!)
        cell.viewTime.text = time
        
        // ustawienie dystansu
        let dist = listOfRoads[indexPath.row].totalLenghtInMeters
        if defaults.bool(forKey: C.keyToSwitchUnitsOnOff) { // jeśli amerykański jednostki są ustawione
            let metersToMiles = (round(Double(dist) * 0.0006213712*1000))/1000 // przeliczenie na mile jeśli są ustawione jednostki US
            cell.viewDist.text = "\(metersToMiles) miles"
        } else {
            cell.viewDist.text = "\(dist) m"
        }
        
        // ustawienie speed
        let speed = listOfRoads[indexPath.row].speedInKmPerH
        if defaults.bool(forKey: C.keyToSwitchUnitsOnOff) { // jeśli amerykański jednostki są ustawione
            let metersToMiles = (round(speed * 0.62*100))/100  // przeliczenie na mile jeśli są ustawione jednostki US
            cell.viewSpeed.text = "\(metersToMiles) miles/h"
        } else {
            cell.viewSpeed.text = "\(speed) km/h"
        }
        cell.accessoryType = .disclosureIndicator // strzałka z prawej każdej Cell
    return cell
    }
    
    //funkcja będzie wywołana gdy się kliknie na item w table View - NIE trzeba robić połączenia w storyboard
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // przejście do kolejnego widoku
        // dane: identifier: ID nadane drugiemu activity w storyboard, po as? nazwa klasy połaczona do drugiego activity
        let vc = storyboard?.instantiateViewController(identifier: "IDSoryboardVewMap") as? ViewControllerMap
        //vc?.nameOfListWithRoadPoints = listOfRoads[indexPath.row].nameOfListWithRoadPoints! //dane które są przekazane do ViewControllerMap
        
        // przekazanie do następnego widoku DANY JEDEN element z listy
        vc?.selectedCategory = listOfRoads[indexPath.row]
        navigationController?.pushViewController(vc!, animated: true)
        
        // po kliknięciu w item odznacza się automatucznie
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // funkcja robi swipable czyli można przesunąć rząd żeby usunąć
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
            
            // usuwanie elementu z tablicy i zapisanie do CoreData
            self.context.delete(self.listOfRoads[indexPath.row]) // usuwa z tablicy związanej z CoreData konkretny obiekt
            self.saveToCoreData() // musi być to zapisane do CoreData
            self.listOfRoads.remove(at: indexPath.row) // usuwa z table view - robi się żeby było widoczne dla UI
            self.tableView.reloadData()
            print("index path of delete: \(indexPath.row)")
            completionHandler(true)
        }

        let swipeActionConfig = UISwipeActionsConfiguration(actions: [delete])
        swipeActionConfig.performsFirstActionWithFullSwipe = false
        return swipeActionConfig
    }
}
