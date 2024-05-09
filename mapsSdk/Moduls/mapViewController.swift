//
//  mapViewController.swift
//  mapsSdk
//
//  Created by monscerrat gutierrez on 06/05/24.
//


//
import UIKit
import GoogleMaps
import CoreLocation
import SwiftUI
import CoreData

class MapViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    let context = PersistenceController.shared.container.viewContext
    
    
    
    // MARK: - Propiedades
    
    var mapView: GMSMapView!
    let button = UIButton(type: .system)
    private var isRecording = false
    private var pathPolyline: GMSPolyline?
    private var locationManager = CLLocationManager()
    private var coordinates = [CLLocation]()
    var tableView: UITableView!
    var routes: [Routes] = []
    var startDate: Date = .now
    var endDate: Date = .now
    
    // MARK: - Ciclo de vida
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configurar la vista del mapa
        setupMapView()
        
        // Configurar la vista de la tabla
        setupTableView()
        
        // Configurar el botón
        setupButton()
        
        // Configurar el administrador de ubicación
        setupLocationManager()
        fetchRoutes()

    }
    
    // MARK: - Configuración de vistas
    
    func setupMapView() {
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 19.640436, longitude: -99.097681, zoom: 15)
        mapView = GMSMapView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 2), camera: camera)
        view.addSubview(mapView)
    }
    
    func setupTableView() {
        tableView = UITableView(frame:  CGRect(x: 0, y: view.frame.height / 2, width: view.frame.width, height: view.frame.height / 2))
        tableView.register(routeListCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }
    
    func setupButton() {
        button.setTitle("Start", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            button.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Acciones
    
    @objc func buttonAction() {
        isRecording.toggle()
        let buttonTitle = isRecording ? "Stop Recording" : "Start Recording"
        button.setTitle(buttonTitle, for: .normal)
        if isRecording {
            startTour()
        } else {
            stopTour()
        }
    }
    
    // MARK: - Funciones
    
    func startTour() {
        print("Iniciando recorrido...")
        
        // Registra la fecha de inicio
        let startDates = Date()
        print(startDates)
        
        // Agregar marcador de inicio de ruta
        let location = locationManager.location
        if let currentLocation = location {
            addMarker(at: currentLocation)
        }
    }
    
    func stopTour() {
        print("Deteniendo recorrido...")
        
        // Registra la fecha de fin
        let endDates = Date()
        print(endDates)
        
        let distanceInMeters = calculateDistanceTraveled()
        let distanceInKilometers = Double(distanceInMeters) / 1000.0
        let formattedDistance = String(format: "%.3f", distanceInKilometers)
        print("Distancia total recorrida: \(formattedDistance) kilómetros")
        
        // Crear el cuadro de texto
        let alertController = UIAlertController(title: "Nombre de la ruta", message: "Ingresa el nombre de la ruta", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "Nombre"
        }
        
        // Agregar acciones al cuadro de texto
        let saveAction = UIAlertAction(title: "Guardar", style: .default) { (_) in
            guard let name = alertController.textFields?.first?.text else { return }
            print("Nombre de la ruta: \(name)")
            self.saveRoute(routeName: name)
        }
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        // Presentar el cuadro de texto
        present(alertController, animated: true, completion: nil)
        
        // Lógica para detener el recorrido en el mapa
        isRecording = false
        let location = locationManager.location
        if let currentLocation = location {
            addMarker(at: currentLocation)
        }
    }
    
    private func addMarker(at coordinate: CLLocation) {
        let marker = GMSMarker()
        marker.position = coordinate.coordinate
        marker.map = mapView
    }
    
    func updatePolyline(with locations: [CLLocation]) {
        let path = GMSMutablePath()
        
        for coordinate in locations {
            path.add(coordinate.coordinate)
            
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = .systemBlue
            polyline.strokeWidth = 3.0
            polyline.map = mapView
        }
    }
    
    func clearRute() {
        mapView.clear()
        coordinates.removeAll()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isRecording, let location = locations.last else { return }
        if isRecording {
            addLocationToRoute(location)
            coordinates.append(location)
            updatePolyline(with: coordinates)
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 15)
            mapView.animate(to: camera)
        }
    }
    
    func calculateDistanceTraveled() -> Double {
        var distance: Double = 0.0
        guard coordinates.count >= 2 else {
            return distance
        }
        for i in 1..<coordinates.count {
            let startPoint = coordinates[i-1]
            let endPoint = coordinates[i]
            let distanceBetweenTwoPoints = startPoint.distance(from: endPoint)
            distance += distanceBetweenTwoPoints
        }
        return distance
    }
    
    func addLocationToRoute(_ coordinate: CLLocation) {
        coordinates.append(coordinate)
    }
    
    //    private func saveRoute(routeName: String) {
    //        guard !coordinates.isEmpty else { return }
    //
    //        let route = Routes(name: routeName, locations: coordinates, startDate: startDate, endDate: endDate, distance: calculateDistanceTraveled())
    //
    //        routes.append(route)
    //        clearRute()
    //        print(routes)
    //        tableView.reloadData()
    //    }
    
    ///////////////////////////////////////////
    
    
    func saveRoute(routeName: String) {
        guard !coordinates.isEmpty else { return }
        // Crear una nueva ruta en el contexto de CoreData
        let newRoute = Routes(context: context)
        newRoute.name = routeName
        newRoute.startDate = startDate
        newRoute.endDate = endDate
        newRoute.distance = calculateDistanceTraveled()
        
        // Agregar las ubicaciones a la ruta
//        for location in coordinates {
//            let newLocation = Location(context: context)
//            newLocation.latitude = location.coordinate.latitude
//            newLocation.longitude = location.coordinate.longitude
//            newLocation.route = newRoute
//        }
        
        // Guardar los cambios en el contexto
        do {
            try context.save()
            print("Ruta guardada correctamente.")
        } catch {
            print("Error al guardar la ruta: \(error)")
        }
        routes.append(newRoute)
        // Limpiar la ruta actual
        clearRute()
        
        // Recargar los datos de la tabla
        tableView.reloadData()
    }
    
    private func fetchRoutes() {
        do {
            routes = try context.fetch(Routes.fetchRequest()) as? [Routes] ?? []
            tableView.reloadData()
        } catch {
            print("Error al recuperar las rutas: \(error)")
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        routes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! routeListCell
        let route = routes[indexPath.row]
        
        cell.nameLabel.text = route.name
        
        let distanceInKilometers = route.distance / 1000
        cell.distanceLabel.text = String(format: "%.2fkm", distanceInKilometers)
        
        return cell
    }
}

class routeListCell: UITableViewCell {
    
    let nameLabel = UILabel()
    let distanceLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupLabels()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabels() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(distanceLabel)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameLabel.bottomAnchor.constraint(equalTo: distanceLabel.topAnchor, constant: -4),
            
            distanceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            distanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            distanceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        nameLabel.font = UIFont.systemFont(ofSize: 20)
        distanceLabel.font = UIFont.systemFont(ofSize: 20)
    }
}

// MARK: - Representable para integrar con SwiftUI

struct ViewControllerBridge: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MapViewController {
        return MapViewController()
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
    }
}
