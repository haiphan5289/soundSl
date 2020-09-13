//
//  MusicModel.swift
//  SoundRain
//
//  Created by Phan Hai on 23/08/2020.
//  Copyright © 2020 Phan Hai. All rights reserved.
//

struct MusicModel: Codable {
    let img: String?
    let title: String?
    let resource: String?
    let url: String?
    
    func aaa() {
        
    }
    
    enum CodingKeys: String, CodingKey {
        case img, title, resource, url
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        img = try values.decodeIfPresent(String.self, forKey: .img)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        resource = try values.decodeIfPresent(String.self, forKey: .resource)
        url = try values.decodeIfPresent(String.self, forKey: .url)
    }
    
}
