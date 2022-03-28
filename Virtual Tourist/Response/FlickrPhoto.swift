//
//  FlickrPhoto.swift
//  Virtual Tourist
//
//  Created by Sam Black on 3/24/22.
//


import Foundation

struct ImageResponse: Codable{
    let photos: responseDetails
    let stat: String
}

struct responseDetails: Codable{
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [PhotoResponse]
}

struct PhotoResponse: Codable{
    let farm: Int
    let height_m: Int
    let id: String
    let isfamily: Int
    let isfriend: Int
    let ispublic: Int
    let owner: String
    let secret: String
    let server: String
    let title: String
    let url_m: String
    let width_m: Int
}
