//
//  PostProductVC.swift
//  SoundRain
//
//  Created by Phan Hai on 22/08/2020.
//  Copyright © 2020 Phan Hai. All rights reserved.
//

import UIKit
import Firebase

class PostProductVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        visualize()
//        login()
    }
    
}
extension PostProductVC {
    private func visualize() {
        self.view.backgroundColor = .white
        
        let imgBG: UIImageView = UIImageView(frame: .zero)
        imgBG.image = UIImage(named: "img_night")
        imgBG.sizeToFit()
        imgBG.contentMode = .scaleAspectFill
        self.view.addSubview(imgBG)
        imgBG.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    private func login() {
        Auth.auth().signIn(withEmail: "guest@gmail.com", password: "123456") { (user, err) in
            guard err == nil else {
                return
            }
            self.postProduct()
        }
    }
    private func postProduct() {
        guard let url = Bundle.main.url(forResource: "soundRain", withExtension: "mp3") else { return }
        do {
            let data = try Data(contentsOf: url)
            self.uploadMp3(data: data)
        } catch let err {
            print(err.localizedDescription)
        }
    }
    private func uploadMp3(data: Data) {
        do {
            // Create a reference to the file you want to upload
            let storageRef = Storage.storage().reference()
            let riversRef = storageRef.child("music/rain")
            
            // Upload the file to the path "images/rivers.jpg"
           riversRef.putData(data, metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                    // Uh-oh, an error occurred!
                    return
                }
                // Metadata contains file metadata such as size, content-type.
                let size = metadata.size
                // You can also access to download URL after upload.
                riversRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        // Uh-oh, an error occurred!
                        return
                    }
                    self.convertStringToData(urlMp3: downloadURL.absoluteString)
                }
            }
        } catch let err {
            print(err.localizedDescription)
        }
    }
    private func convertStringToData(urlMp3: String) {
        guard let url = UIImage(named: "img_rain_night"), let data = url.pngData() else { return }
        self.uploadToFirebase(urlMp3: urlMp3, data: data)
    }
    private func uploadToFirebase(urlMp3: String, data: Data) {
        do {
            // Create a reference to the file you want to upload
            let storageRef = Storage.storage().reference()
            let riversRef = storageRef.child("imgMusic/rain")
            
            // Upload the file to the path "images/rivers.jpg"
            let uploadTask = riversRef.putData(data, metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                    // Uh-oh, an error occurred!
                    return
                }
                // Metadata contains file metadata such as size, content-type.
                let size = metadata.size
                // You can also access to download URL after upload.
                riversRef.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        // Uh-oh, an error occurred!
                        return
                    }
                    let dataDic: [String: Any] = ["title": "Tiếng mưa rơi",
                                                  "img":downloadURL.absoluteString,
                                                  "url": urlMp3,
                    ]
                    FirebaseDatabase.instance.ref.child("\(FirebaseTable.sound.table)").childByAutoId().setValue(dataDic)
                }
            }
        } catch let err {
            print(err.localizedDescription)
        }
    }
}
class FirebaseDatabase {
    static var instance = FirebaseDatabase()
    var ref: DatabaseReference = Database.database().reference()
    var storage = Storage.storage().reference()
}
enum FirebaseTable {
    case sound
    case listFeedBack
    case tips
    
    var table: String {
        switch self {
        case .sound:
            return "Sound"
        case .listFeedBack:
            return "listFeedBack"
        case .tips:
            return "Tips"
        }
    }
}
