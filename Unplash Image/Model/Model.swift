//
//  Model.swift
//  Unplash Image
//
//  Created by Atul Kumar Verma on 16/04/24.
//

import Foundation

//MARK: - Model for Unsplash photo
struct UnsplashPhoto: Codable {
    let urls: URLSet

    struct URLSet: Codable {
        let regular: String
    }
}
