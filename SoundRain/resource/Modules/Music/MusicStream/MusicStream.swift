//
//  MusicStream.swift
//  SoundRain
//
//  Created by Phan Hai on 01/09/2020.
//  Copyright © 2020 Phan Hai. All rights reserved.
//
import UIKit
import RxCocoa
import RxSwift
import AVFoundation
import RxRelay
import Realm
import RealmSwift

protocol MusicStream {
    var dataSource: BehaviorSubject<[MusicModel]> { get }
    //    func playIndexItem(idx: IndexPath)
}
final class MusicStreamIpl: MusicStream {
    var dataSource: BehaviorSubject<[MusicModel]> = BehaviorSubject.init(value: [])
    var miniValue: TimeInterval = 0
    var maxValue: TimeInterval = 0
    private var miniValueObs: PublishSubject<TimeInterval> = PublishSubject.init()
    private var maxValueObs: PublishSubject<TimeInterval> = PublishSubject.init()
    var listMusiceFavourite: BehaviorRelay<[MusicModel]> = BehaviorRelay.init(value: [])
    var listLoved: [MusicModel] = []
    var names: Results<MyObject>?
    let realm = try! Realm()
    var audio: AVAudioPlayer?
    let data = ExampleData2()
    private let disposeBag = DisposeBag()
    init() {
        dummyData()
        setupRX()
    }
}
extension MusicStreamIpl {
    private func dummyData() {
        let data1: MusicModel = MusicModel(img: "img_rain_night", title: "Tiếng mưa đêm", resource: "soundRain")
        let data2: MusicModel = MusicModel(img: "img_rain_night", title: "Tiếng nước chảy và Piano", resource: "nuocchayandAudio")
        let data = [data1, data2]
        dataSource.onNext(data)
    }
    private func setupRX() {
        self.maxValueObs.asObserver().bind { (value) in
            self.maxValue = value
        }.disposed(by: disposeBag)
        
        self.listMusiceFavourite.asObservable().bind { (value) in
            self.listLoved = value
            self.writeRealm(list: value)
//            self.addName(text: "lll")
            self.arrayToList()
            self.loadPeople()
        }.disposed(by: disposeBag)
        
    }
    func updateListLove(item: MusicModel) {
        var listCurrent = self.listMusiceFavourite.value
        listCurrent.append(item)
        self.listMusiceFavourite.accept(listCurrent)
    }
    
    func removeListLove(item: MusicModel) {
        var list = self.listLoved
        self.listLoved.enumerated().forEach { (value) in
            if (value.element.resource == item.resource) {
                list.remove(at: value.offset)
            }
        }
        self.listMusiceFavourite.accept(list)
    }
    private func writeRealm(list: [MusicModel]) {
        guard list.count > 0 else {
            return
        }
//        data.listItem = list
//        data.name = [1,2]
//        do {
//            try realm.write {
//                realm.add(data)
//            }
//        } catch {
//            print("Error add data")
////        }
//        let newName = ExampleData()
//        newName.name = "Hải"
//        do {
//            try realm.write {
//                realm.add(newName)
//            }
//        } catch {
//            print("Error add data")
//        }
    }
//    private func addName(text: String) {
////        let newName = ExampleData()
////        newName.name.append(1)
//        let check = List<MyObject>()
//        let a: MyObject = MyObject()
//        check.append(a)
//
//        do {
//            try realm.write {
//                realm.add(a)
//            }
//        } catch {
//            print("Error add data")
//        }
//    }
    func arrayToList() {
        let b = LisResourceItem()
        b.key = "hải"
        b.value = "phan"
        let c = MyObject()
        c.name.append(b)
        let objectsArray = [MyObject(), MyObject(), MyObject(), MyObject(), MyObject(), c]
//        let a: MyObject = MyObject()
//        a.name = 1
//        let objectsArray = [a, a]
        let objectsRealmList = List<MyObject>()

        // this one is illegal
        //objectsRealmList = objectsArray

        for object in objectsArray {
            objectsRealmList.append(object)
        }

        // storing the data...
        let realm = try! Realm()
        try! realm.write {
            realm.add(objectsRealmList)
        }
    }
    private func loadPeople () {
        names = realm.objects(MyObject.self)
        names?.forEach({ (item) in
            print(item.name)
        })
    }
}
