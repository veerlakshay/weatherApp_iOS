//
//  ViewController.swift
//  weatherApp
//
//  Created by Lakshay Veer on 2024-11-03.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {

    @IBOutlet weak var searchBar: UITextField!
    
    @IBOutlet weak var tempLabel: UILabel!
    
    @IBOutlet weak var weatherImage: UIImageView!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    var locationManager: CLLocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        weatherImage.image = UIImage(systemName: "globe")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
           tapGesture.cancelsTouchesInView = false
           view.addGestureRecognizer(tapGesture)
        
        searchBar.delegate = self
      
    }
    
    @IBAction func searchBtn(_ sender: Any) {
        loadWeather(search: searchBar.text)
    }
    
    @IBAction func locationBtn(_ sender: Any) {
        
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
                      
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.showsBackgroundLocationIndicator = true
        
        locationManager?.requestAlwaysAuthorization()
        
        
        requestLocationUpdate()
        
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func requestLocationUpdate() {
           locationManager?.startUpdatingLocation()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        performAction()
        return true
    }
    
    @objc func performAction() {
        loadWeather(search: searchBar.text)
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            print("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
        
         getCityName(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { cityName in
            if let cityName = cityName {
                self.loadWeather(search: cityName)
            } else {
                print("City name not found")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
           locationManager?.stopUpdatingLocation()

           if let clErr = error as? CLError {
               switch clErr.code {
               case .locationUnknown, .denied, .network:
                   print("Location request failed with error: \(clErr.localizedDescription)")
               case .headingFailure:
                   print("Heading request failed with error: \(clErr.localizedDescription)")
               case .rangingUnavailable, .rangingFailure:
                   print("Ranging request failed with error: \(clErr.localizedDescription)")
               case .regionMonitoringDenied, .regionMonitoringFailure, .regionMonitoringSetupDelayed, .regionMonitoringResponseDelayed:
                   print("Region monitoring request failed with error: \(clErr.localizedDescription)")
               default:
                   print("Unknown location manager error: \(clErr.localizedDescription)")
               }
           } else {
               print("Unknown error occurred while handling location manager error: \(error.localizedDescription)")
           }
       }

    //getting city name from location
    func getCityName(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first, let city = placemark.locality else {
                print("City not found")
                completion(nil)
                return
            }
            
            completion(city)
        }
    }

    

   
    private func loadWeather(search : String?){
        guard let search = search else {
            return
        }
        
        guard let url = getUrl(searchLocation: search) else{
            print("No valid url found")
            return
        }
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: url){ data , response , error in
            print("Network call successfull")
            
            guard error == nil else{
                print("Error")
                return
            }
            
            guard let data = data else{
                print("No data avaiable")
                return
            }
            
            if let weatherResponse = self.decodeJson(data: data) {
                print(weatherResponse.location.name)
                print(weatherResponse.current.temp_c)
                
                DispatchQueue.main.async{
                    self.locationLabel.text = weatherResponse.location.name
                    self.tempLabel.text = "\(weatherResponse.current.temp_c) °C"
                    self.weatherImage.image = UIImage(systemName: self.getImageFromCode(code: weatherResponse.current.condition.code))
                }
                
            }
            
        }
        
        dataTask.resume()
    }
    
    private func getImageFromCode(code : Int) -> String {
        
        let weatherConditions: [Int: String] = [
            1000: "sun.max",
            1003: "cloud.sun",
            1006: "cloud",
            1087: "cloud.bolt",
            1153: "cloud.rain",
            1168: "cloud.rain",
            1171: "cloud.rain",
            1180: "cloud.rain",
            1183: "cloud.rain",
            1186: "cloud.rain",
            1189: "cloud.rain",
            1192: "Dcloud.rain",
            1195: "cloud.rain",
            1198: "cloud.rain",
            1201: "cloud.rain",
            1210: "cloud.snow",
            1213: "cloud.snow",
            1216: "cloud.snow",
            1219: "cloud.snow",
            1222: "cloud.snow",
            1225: "cloud.snow",
            1276: "cloud.bolt.rain",
            1279: "cloud.bolt.rain",
            1282: "cloud.bolt.rain"
        ]

        return weatherConditions[code] ?? "globe"

    }
    
    private func decodeJson(data : Data) -> WeatherData? {
        let decoder = JSONDecoder()
        var weather: WeatherData?
        
        do{
            weather = try decoder.decode(WeatherData.self, from: data)
        } catch{
            print("Error in decoding")
        }
        
        return weather
    }
    
    private func getUrl(searchLocation : String) -> URL? {
        
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndPoint = "current.json"
        let apiKey = "c1d1d1487c01480094d00623240411"
        
        guard let url = "\(baseUrl)\(currentEndPoint)?key=\(apiKey)&q=\(searchLocation)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return URL(string: url)
    }

}

struct WeatherData : Decodable{
    let location : Location
    let current : Weather
}

struct Location  : Decodable{
    let name : String
}

struct Weather  : Decodable{
    let temp_c : Float
    let condition : WeatherCondition
}

struct WeatherCondition  : Decodable{
    let text : String
    let code : Int
}
