//
//  PhotoAPI.swift
//  Virtual Tourist
//
//  Created by Sam Black on 3/26/22.
//

import Foundation
import UIKit


class PhotoAPI {

    var pin: Pin!

    
    enum Endpoints {
        // my API Key from Flickr
        static let apiKey = "8022ce99730092fc3f9cf6d930b0e38a"
        // Base URL Defined in Flickr Docs https://www.flickr.com/services/api/request.rest.html
        static let base = "https://api.flickr.com/services/rest/"
        // method specified in Flickr API docs
        static let method = "?&method=flickr.photos.search"
        case imageCriteria(lat: Double, long: Double, page: Int, perPage: Int, contentType: Int)

        var URLString: String{
            switch self {
            case .imageCriteria(let lat, let long, let page, let perPage, let contentType):
                return Endpoints.base + Endpoints.method + "&api_key=\(Endpoints.apiKey)" + "&lat=\(lat)" + "&lon=\(long)" + "&per_page=\(perPage)" + "&format=json&nojsoncallback=1&extras=url_m"
                }
            }
            var url: URL{
                    return URL(string: URLString)!
        }
    }
    
    // getPhotos takes parameters which will make photo specific to selected pin
    // https://stackoverflow.com/questions/46245517/swift-escaping-and-completion-handler
    // completionHandler is @ escaping: Escaping Closure : An escaping closure is a closure that’s called after the function it was passed to returns. In other words, it outlives the function it was passed to.
    
    class func getPhotos(lat: Double, long: Double, page: Int, perPage: Int, completionHandler: @escaping ([PhotoResponse]?,Error?) -> Void) {
        print("calling getPhotos....")
        print("LAT:_________")
        print(lat)
        print("---------")
        var url = Endpoints.imageCriteria(lat: lat, long: long, page: page, perPage: 8, contentType: 1).url
        var request = URLRequest(url: Endpoints.imageCriteria(lat: lat, long: long, page: page, perPage: 4, contentType: 1).url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request, completionHandler: {(data,response,error) in
            // Print out Data in String format
            print("Data:")
            print(String(data: data!, encoding: .utf8) as Any)
            // if error is not none
            if error != nil {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            do{
                //Decode response from JSON format
                print("Json:****")
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                print(json)
                // Tru to decode image response from the data
                let response = try JSONDecoder().decode(ImageResponse.self, from: data!)
                print("Response************")
                print(response)
                print("---------------------")
                print("Response************")
                // pass response.photos.photo as [FlickrResponse]. This is an array of photos, and compeltes the function
                DispatchQueue.main.async {
                    completionHandler(response.photos.photo, nil)
                }
            } catch{
                //if data is not none but can't decode response from JSON
                print(error)
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        })
        task.resume()
    }
    
    // Gets image at specified index within PhotoResponse
    class func getImageAt(index: Int,  response: [PhotoResponse], completionHandler: @escaping (UIImage?,Error?) -> Void){
        let imgURL = URL(string: response[index].url_m)
        DispatchQueue.global(qos: .userInteractive).async {
            // Download image
            do{
                let imgData = try Data(contentsOf: imgURL!)
                DispatchQueue.main.async {
                    completionHandler(UIImage(data: imgData), nil)
                }
            }catch{
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }
    }
    
    
}
