//
//  PhotoAPI.swift
//  Virtual Tourist
//
//  Created by Sam Black on 3/26/22.
//

import Foundation
import UIKit


class PhotoAPI {

    static var pageCount:Int = 1
    var pin: Pin!
    var dataController:DataController!

    
    enum Endpoints {
        // my API Key from Flickr
        static let apiKey = "8022ce99730092fc3f9cf6d930b0e38a"
        // Base URL Defined in Flickr Docs https://www.flickr.com/services/api/request.rest.html
        static let base = "https://www.flickr.com/services/rest/"
        static let method = "?&method=flickr.photos.search"
        case imageCriteria(long: Double, lat: Double, page: Int, perPage: Int, contentType: Int)

        var URLString: String{
            switch self {
            case .imageCriteria(let lat, let long, let page, let perPage, let contentType):
                return Endpoints.base + Endpoints.method + "&api_key=\(Endpoints.apiKey)" + "&lat=\(lat)" + "&lon=\(long)" + "&radius=20" + "&page=\(page)" + "&per_page=\(perPage)" + "&content_type=\(contentType)" + "&format=json&nojsoncallback=1&extras=url_m"
                }
            }
            var url: URL{
                    return URL(string: URLString)!
        }
    }
    
    // getPhotos takes parameters which will make photo specific to selected pin
    // https://stackoverflow.com/questions/46245517/swift-escaping-and-completion-handler
    // completionHandler is @ escaping: Escaping Closure : An escaping closure is a closure that’s called after the function it was passed to returns. In other words, it outlives the function it was passed to.
    
    class func getPhotos(lat: Double, long: Double, page: Int, perPage: Int, completionHandler: @escaping ([FlickrResponse]?,Error?) -> Void) {
        print("calling getPhotos....")
        //dataController = DataController(modelName: "VirtualTourist")
        //dataController.load()
        print("LAT:_________")
        print(lat)
        print("---------")
        let task = URLSession.shared.dataTask(with: URLRequest(url: Endpoints.imageCriteria(long: long, lat: lat, page: page, perPage: perPage, contentType: 1).url), completionHandler: {(data,response,error) in
            // if data is none, meaning fetch did not work
            guard let data = data else{
                // Throw error
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            do{
                //Decode response from JSON format
                let response = try JSONDecoder().decode(FlickrResponse.self, from: data)
                //set number of pages of photos available
                pageCount = response.photos.pages
                // pass response.photos.photo as [FlickrResponse]. This is an array of photos.
                DispatchQueue.main.async {
                    completionHandler(response.photos.photo, nil)
                }
            } catch{
                //if data is not none but can't decode response from JSON
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        })
        task.resume()
    }
    
    class func getRandomPage()->Int{
        return Int.random(in: 1...pageCount)
    }
    
    // Parameters are index (to be used to select photo number in FlickrResponse array), response (FlickrResponse, which is an array of pictures)
    // completionHandler is @ escaping: Escaping Closure : An escaping closure is a closure that’s called after the function it was passed to returns. In other words, it outlives the function it was passed to.
    // getImageAt completes once image is retrieved (or not, which is why there's a ?), and error (or not, which is why there is a ?)
    class func getImageAt(index: Int,  response: [FlickrResponse], completionHandler: @escaping (UIImage?,Error?) -> Void){
        let imgURL = URL(string: response[index].photoURL)
        DispatchQueue.global(qos: .userInteractive).async {
            // Download image on background thread, using retrieved image
            do{
                let imgData = try Data(contentsOf: imgURL!)
                DispatchQueue.main.async {
                    completionHandler(UIImage(data: imgData), nil)
                }
            // Throw error
            }catch{
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }
    }
    
    
}
