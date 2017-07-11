//
//  ViewController.swift
//  MapsProject
//
//  Created by MacBook on 7/11/17.
//  Copyright © 2017 Mazzica1. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController,CLLocationManagerDelegate{
    @IBOutlet weak var buttonGetYourLocation: UIButton!
    @IBOutlet weak var labelTotalDistance: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet var lblAddressFrom: UILabel!
    @IBOutlet var lblAddress2From: UILabel!
    
    @IBOutlet weak var destinationLocationStackViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var yourLocationStackViewHeightConstraint: NSLayoutConstraint!
    var locationManager = CLLocationManager()
    var placesClient: GMSPlacesClient!
    
    @IBOutlet weak var lblAddress1To: UILabel!
    
    @IBOutlet weak var lblAddress2To: UILabel!
    
    var streetNo: String = ""
    var route: String = ""
    var neighborhood: String = ""
    var locality: String = ""
    var administrative_area_level_1: String = ""
    var country: String = ""
    var postalAddressCode: String = ""
    var postalAddressCodeSuffix: String = ""
    var fromLocation,toLocation:CLLocation?
    var getLocationFrom = false,getLocationTo=false
    
    
    func showInternetNotAvailableError() {
        let alertController = UIAlertController(title: "", message: "Check your conection.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .destructive, handler: { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        labelTotalDistance.text = ""
        labelTotalDistance.isHidden = true
        placesClient = GMSPlacesClient.shared()
        yourLocationStackViewHeightConstraint.constant = 0
        destinationLocationStackViewHeightConstraint.constant = 0
    }
    @IBAction func autoCompleteFrom(_ sender: Any) {
        getLocationTo=false
        getLocationFrom=true
        openGetLocation()
    }
    
    
    @IBAction func autocompleteClicked(_ sender: UIButton) {
        getLocationTo=true
        getLocationFrom=false
        openGetLocation()
        
    }
    
    func openGetLocation() {
        //show error if internet is not available
        if NSObject.currentReachabilityStatus == .notReachable {
            showInternetNotAvailableError()
            return
        }
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        // Set a filter to return only addresses.
        let addressFilter = GMSAutocompleteFilter()
        addressFilter.type = .address
        autocompleteController.autocompleteFilter = addressFilter
        
        present(autocompleteController, animated: true, completion: nil)
    }
    
    
    func fillAddress() {
        if getLocationTo {
            lblAddress1To.text = streetNo + " " + route + " " + locality
            var postalCode = ""
            if postalAddressCodeSuffix != "" {
                postalCode = postalAddressCode + "-" + postalAddressCodeSuffix
            } else {
                postalCode = postalAddressCode
            }
            lblAddress2To.text = administrative_area_level_1 + " " + country + " " + postalCode
            destinationLocationStackViewHeightConstraint.constant = 50
        }else if getLocationFrom {
            lblAddressFrom.text = streetNo + " " + route + " " + locality
            var postalCode = ""
            if postalAddressCodeSuffix != "" {
                postalCode = postalAddressCode + "-" + postalAddressCodeSuffix
            } else {
                postalCode = postalAddressCode
            }
            lblAddress2From.text = administrative_area_level_1 + " " + country + " " + postalCode
            yourLocationStackViewHeightConstraint.constant = 50
        }
        
        streetNo = ""
        route = ""
        neighborhood = ""
        locality = ""
        administrative_area_level_1  = ""
        country = ""
        postalAddressCode = ""
        postalAddressCodeSuffix = ""
    }
    
    
    override func loadView() {
        super.loadView()
        
        //show my location
        self.mapView.isMyLocationEnabled = true
        
        // Location Manager code to fetch current location
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()
    }
    
    //Location Manager delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        
        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, zoom: 17.0)
        
        mapView.animate(to: camera)
        
        self.locationManager.stopUpdatingLocation()
        
        
    }
    
    
}

extension ViewController: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        if let addressLines = place.addressComponents {
            for field in addressLines {
                switch field.type {
                case kGMSPlaceTypeStreetNumber:
                    streetNo = field.name
                case kGMSPlaceTypeRoute:
                    route = field.name
                case kGMSPlaceTypeNeighborhood:
                    neighborhood = field.name
                case kGMSPlaceTypeLocality:
                    locality = field.name
                case kGMSPlaceTypeAdministrativeAreaLevel1:
                    administrative_area_level_1 = field.name
                case kGMSPlaceTypeCountry:
                    country = field.name
                case kGMSPlaceTypePostalCode:
                    postalAddressCode = field.name
                case kGMSPlaceTypePostalCodeSuffix:
                    postalAddressCodeSuffix = field.name
                default:
                    print("")
                }
            }
        }
        
        fillAddress()
        
        
        self.dismiss(animated: true, completion: nil)
        
        if getLocationTo {
            toLocation=CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        }
        
        if getLocationFrom {
            fromLocation=CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        }
        
        if fromLocation == nil || toLocation == nil {
            return
        }
        //Calculate distance between source and destination
        
        let distance = (fromLocation!.distance(from: toLocation!)) / 1000.0 //convert into km
        
        
        labelTotalDistance.isHidden = false
        labelTotalDistance.text = String(format: "Distance: %.2f KM",distance)
        
        let fromLocation2d = CLLocationCoordinate2D(latitude: (fromLocation!.coordinate.latitude), longitude: (fromLocation!.coordinate.longitude))
        let toLocation2d = CLLocationCoordinate2D(latitude: toLocation!.coordinate.latitude, longitude: toLocation!.coordinate.longitude)
        
        //Draw route
        getPolylineRoute(from: fromLocation2d, to: toLocation2d)
        
        //Put marker for destination
        var marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: (toLocation?.coordinate.latitude)!, longitude: (toLocation?.coordinate.longitude)!)
        marker.title = place.name
        marker.snippet = place.formattedAddress
        marker.map = mapView
        
        //Put marker for Pickup
        marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: (fromLocation?.coordinate.latitude)!, longitude: (fromLocation?.coordinate.longitude)!)
        marker.title = place.name
        marker.snippet = place.formattedAddress
        marker.map = mapView
        
        //zoom to proper region so that sourc and destination will be visible properly
        var region:GMSVisibleRegion = GMSVisibleRegion()
        region.nearLeft = CLLocationCoordinate2DMake((fromLocation!.coordinate.latitude), (fromLocation!.coordinate.longitude))
        region.farRight = CLLocationCoordinate2DMake(toLocation!.coordinate.latitude,toLocation!.coordinate.longitude)
        let bounds = GMSCoordinateBounds(coordinate: region.nearLeft,coordinate: region.farRight)
        let camera = self.mapView.camera(for:bounds, insets:UIEdgeInsets(top: 150, left: 150, bottom: 150, right: 150))
        
        mapView.camera = camera!;
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Show the network activity indicator.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    // Hide the network activity indicator.
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
extension ViewController{
    
    // Pass your source and destination coordinates in this method.
    func getPolylineRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D){
        
        //show error if internet is not available
        if NSObject.currentReachabilityStatus == .notReachable {
            showInternetNotAvailableError()
            return
        }
        
        //clear all previous markers and routes if any
        mapView.clear()
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let url = URL(string: "http://maps.googleapis.com/maps/api/directions/json?origin=\(source.latitude),\(source.longitude)&destination=\(destination.latitude),\(destination.longitude)&sensor=false&mode=driving&alternatives=true")!
        
        let task = session.dataTask(with: url, completionHandler: {
            (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }else{
                do {
                    if let json : [String:Any] = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any]{
                        
                        let routes = json["routes"] as? [Any]
                        
                        for  index in (0..<routes!.count){
                            let overview_polyline = routes?[index] as?[String:Any]
                            let overview_polyline1 = overview_polyline?["overview_polyline"] as?[String:Any]
                            let polyString = overview_polyline1?["points"] as? String
                            
                            var linecolor = UIColor.blue
                            if index != 0{
                                linecolor = UIColor.darkGray
                            }
                            
                            //Call this method to draw path on map
                            self.showPath(polyStr: polyString!,lineColor:linecolor)
                        }
                        
                    }
                    
                }catch{
                    print("error in JSONSerialization")
                }
            }
        })
        task.resume()
    }
    
    func showPath(polyStr :String,lineColor:UIColor){
        DispatchQueue.main.async {
            let path = GMSPath(fromEncodedPath: polyStr)
            let polyline = GMSPolyline(path: path)
            polyline.strokeWidth = 3.0
            polyline.strokeColor = lineColor
            polyline.map = self.mapView
        }
        
    }
}


