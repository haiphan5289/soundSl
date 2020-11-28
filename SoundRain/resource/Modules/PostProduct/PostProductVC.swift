//
//  PostProductVC.swift
//  SoundRain
//
//  Created by Phan Hai on 22/08/2020.
//  Copyright © 2020 Phan Hai. All rights reserved.
//

import UIKit
import Firebase
import RxCocoa
import RxSwift

class PostProductVC: UIViewController {
    
    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        visualize()
        login()
        setupRX()
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
    private func setupRX() {
//        self.urlMp3Obserable().bind(onNext: weakify({ (value, wSelf) in
//            print(value)
//            })).disposed(by: disposeBag)
        Observable.combineLatest(self.uploadImage(), self.urlMp3Obserable()).bind { (img, url) in
            let dataDic: [String: Any] = ["title": "Tiếng nước chảy",
                                          "img":img,
                                          "url": url,
            ]
            FirebaseDatabase.instance.ref.child("\(FirebaseTable.sound.table)").childByAutoId().setValue(dataDic)
        }.disposed(by: disposeBag)
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
        guard let url = Bundle.main.url(forResource: "the_sound_of_running_water", withExtension: "mp3") else { return }
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
            let riversRef = storageRef.child("music/\(Date().timeIntervalSince1970)the_sound_of_running_water.mp3")
            
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
        guard let url = UIImage(named: "soundWater"), let data = url.pngData() else { return }
        self.uploadToFirebase(urlMp3: urlMp3, data: data)
    }
    private func uploadToFirebase(urlMp3: String, data: Data) {
//        do {
//            // Create a reference to the file you want to upload
//            let storageRef = Storage.storage().reference()
//            let riversRef = storageRef.child("imgMusic/\(Date().timeIntervalSince1970)piano")
//
//            // Upload the file to the path "images/rivers.jpg"
//            let uploadTask = riversRef.putData(data, metadata: nil) { (metadata, error) in
//                guard let metadata = metadata else {
//                    // Uh-oh, an error occurred!
//                    return
//                }
//                // Metadata contains file metadata such as size, content-type.
//                let size = metadata.size
//                // You can also access to download URL after upload.
//                riversRef.downloadURL { (url, error) in
//                    guard let downloadURL = url else {
//                        // Uh-oh, an error occurred!
//                        return
//                    }
//                    let dataDic: [String: Any] = ["title": "Tiếng piano",
//                                                  "img":downloadURL.absoluteString,
//                                                  "url": urlMp3,
//                    ]
//                    FirebaseDatabase.instance.ref.child("\(FirebaseTable.sound.table)").childByAutoId().setValue(dataDic)
//                }
//            }
//        } catch let err {
//            print(err.localizedDescription)
//        }
    }
    private func urlMp3Obserable() -> Observable<String> {
        return Observable.create { (obser) -> Disposable in
            guard let url = Bundle.main.url(forResource: "the_sound_of_running_water", withExtension: "mp3") else { return  Disposables.create()}
            do {
                let data = try Data(contentsOf: url)
                
                do {
                    // Create a reference to the file you want to upload
                    let storageRef = Storage.storage().reference()
                    let riversRef = storageRef.child("music/\(Date().timeIntervalSince1970)the_sound_of_running_water.mp3")
                    
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
                            obser.onNext(downloadURL.absoluteString)
                        }
                    }
                } catch let err {
                    print(err.localizedDescription)
                }
            } catch let err {
                print(err.localizedDescription)
            }
            return Disposables.create()
        }
        
    }
    private func uploadImage() -> Observable<String> {
           return Observable.create { (obser) -> Disposable in
               guard let url = UIImage(named: "soundWater"), let data = url.pngData() else { return  Disposables.create()}
                do {
                          // Create a reference to the file you want to upload
                          let storageRef = Storage.storage().reference()
                          let riversRef = storageRef.child("imgMusic/\(Date().timeIntervalSince1970)soundWater.jpg")
                          
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
                                obser.onNext(downloadURL.absoluteString)
                              }
                          }
                      } catch let err {
                          print(err.localizedDescription)
                      }
               return Disposables.create()
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
