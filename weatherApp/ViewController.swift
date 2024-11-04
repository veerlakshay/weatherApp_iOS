//
//  ViewController.swift
//  weatherApp
//
//  Created by Lakshay Veer on 2024-11-03.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var searchBar: UITextField!
    
    @IBOutlet weak var tempLabel: UILabel!
    
    @IBOutlet weak var weatherImage: UIImageView!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        weatherImage.image = UIImage(systemName: "globe")
    }
    
    @IBAction func searchBtn(_ sender: Any) {
        loadWeather(search: searchBar.text)
    }
    
    @IBAction func locationBtn(_ sender: Any) {
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
            print("Nrtwork call successfull")
            
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
                    self.tempLabel.text = "\(weatherResponse.current.temp_c) C"
                }
                
            }
            
        }
        
        dataTask.resume()
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
