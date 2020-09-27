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
import Firebase
import Alamofire

protocol MusicStream {
    var dataSource: BehaviorSubject<[MusicModel]> { get }
    var item: Observable<MusicModel> { get }
    var currentIndexItem: Observable<IndexPath> { get }
    var isPlaying: Observable<Bool> { get }
    var isEndAudio: Observable<Bool> { get }
    var currentTime: Observable<TimeInterval> { get }
}
final class MusicStreamIpl: MusicStream {
    public static var share = MusicStreamIpl()
    var item: Observable<MusicModel> {
        return self.$itemOb
    }
    var currentIndexItem: Observable<IndexPath> {
        return self.$currentIndex
    }
    
    var isPlaying: Observable<Bool> {
        return self.$isPlay
    }
    var isEndAudio: Observable<Bool> {
        return self.$isEndAudioObser
    }
    var currentTime: Observable<TimeInterval> {
        return self.$mCurrentTime
    }
    @Replay(queue: MainScheduler.asyncInstance) private var itemOb: MusicModel
    @Replay(queue: MainScheduler.asyncInstance) private var currentIndex: IndexPath
    @Replay(queue: MainScheduler.asyncInstance) private var isPlay: Bool
    @Replay(queue: MainScheduler.asyncInstance) var isEndAudioObser: Bool
    @Replay(queue: MainScheduler.asyncInstance) private var mCurrentTime: TimeInterval
    private var aaa: BehaviorRelay<MusicModel?> = BehaviorRelay(value: nil)
    var dataSource: BehaviorSubject<[MusicModel]> = BehaviorSubject.init(value: [])
    private var mSource: [MusicModel] = []
    var miniValue: TimeInterval = 0
    var maxValue: TimeInterval = 0
//    private var miniValueObs: PublishSubject<TimeInterval> = PublishSubject.init()
//    private var maxValueObs: PublishSubject<TimeInterval> = PublishSubject.init()
    var itemCheck = ReplaySubject<String?>.create(bufferSize: 1)
    var maxValueSlider: PublishSubject<Double> = PublishSubject.init()
    var listMusiceFavourite: BehaviorRelay<[MusicModel]> = BehaviorRelay.init(value: [])
    var listLoved: [MusicModel] = []
    var names: Results<MyObject>?
    let realm = try! Realm()
    var audio: AVAudioPlayer?
    let data = ExampleData2()
    private let disposeBag = DisposeBag()
}
extension MusicStreamIpl {
    private func dummyData() {
        var data: [MusicModel] = []
        let dataBase = Database.database().reference()
        dataBase.child("\(FirebaseTable.sound.table)").observe(.childAdded) { (snapShot) in
            if let user = self.convertDataSnapshotToCodable(data: snapShot, type: MusicModel.self) {
                data.append(user)
                self.dataSource.onNext(data)
            }
        }
    }
    func setupRX() {
        dummyData()
        
        self.listMusiceFavourite.asObservable().bind { (value) in
            self.listLoved = value
            self.writeRealm(list: value)
            self.arrayToList()
            self.loadPeople()
        }.disposed(by: disposeBag)
        
        self.dataSource.asObserver().bind { [weak self] (datas) in
            guard let wSelf = self else {
                return
            }
            wSelf.mSource = datas
        }.disposed(by: disposeBag)
        
        let timer = Observable<Int>.interval(RxTimeInterval.milliseconds(1000), scheduler: MainScheduler.asyncInstance)
        let isEndAudio = self.$isEndAudioObser
        
        Observable.combineLatest(timer, isEndAudio).bind { [weak self] (time, isEnd) in
            guard !isEnd else {
                return
            }
            
            guard let wSelf = self else {
                return
            }
            
            guard let current = wSelf.audio?.currentTime else {
                return
            }
            
            wSelf.mCurrentTime = current
            
        }.disposed(by: disposeBag)
        
//        let end = NotificationCenter.rx.
        
//                NotificationCenter.default.rx.notification(NSNotification.Name.AVPlayerItemDidPlayToEndTime).bind { (isNo) in
//                    print(isNo)
//                }.disposed(by: disposeBag)
//        timer.bind(onNext: { _ in
//            print(self.audio?.currentTime)
//            }).disposed(by: disposeBag)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        
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
   func getIndex(idx: IndexPath) {
    self.itemCheck.onNext("sssss")
    
        guard let text = self.mSource[idx.row].url else {
            return
        }
    let item = self.mSource[idx.row]
    self.itemOb = item
    self.currentIndex = idx
        self.playSound(text: text)
    }
    
    private func playSound(text: String) {
        guard  let url = URL(string: text) else {
            return
        }
        downloadFileFromURL(url: url)
        
        //            do {
        //                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
        //                try AVAudioSession.sharedInstance().setActive(true)
        //
        ////                 The following line is required for the player to work on iOS 11. Change the file type accordingly
        ////                audio = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
        //                /* iOS 10 and earlier require the following line:
        //                player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
        //
        //                guard let player = audio else { return }
        //
        //                player.pause()
        ////                slideMusic.minimumValue = 0
        ////                slideMusic.maximumValue = Float(player.duration)
//                        let m = Int(player.duration / 60)
//                        let s = Int(player.duration) % 60
//                        lbEnd.text = "\(m):\(s)"
        //                player.play()
        ////                timer = Observable<Int>.interval(RxTimeInterval.milliseconds(1000), scheduler: MainScheduler.asyncInstance)
        //            } catch let error {
        //                print(error.localizedDescription)
        //            }
    }
    private func downloadFileFromURL(url:URL){
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            documentsURL.appendPathComponent("file.csv")
            return (documentsURL, [.removePreviousFile])
        }
        
        Alamofire.download(url, to: destination).responseData { response in
            if let destinationUrl = response.destinationURL {
                self.play(url: destinationUrl.absoluteURL)
            }
        }
        
    }
    private func play(url:URL) {
        do {
            self.audio = try AVAudioPlayer(contentsOf: url)
            audio?.prepareToPlay()
            audio?.play()
            self.isPlay = true
            guard let max = audio?.duration else {
                return
            }
            self.maxValueSlider.onNext(max)
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
        
    }
    
    func playingAudio() {
        audio?.play()
        self.isPlay = true
    }
    
    func stopAudio() {
        audio?.stop()
        self.isPlay = false
    }
}
extension MusicStreamIpl {
    func convertDataSnapshotToCodable<T: Codable> (data: DataSnapshot, type: T.Type) -> T? {
        do {
            let value = try JSONSerialization.data(withJSONObject: data.value, options: .prettyPrinted)
            let objec = try JSONDecoder().decode(T.self, from: value)
            return objec
        } catch let err {
            print(err.localizedDescription)
        }
        return nil
    }
}

protocol checkaaa {
    var item: Observable<Int> { get }
}

class checkOb {
    public static var share = checkOb()
    var it: ReplaySubject<[Int]> = ReplaySubject.create(bufferSize: 1)
}
extension checkOb {
    func setup() {
        self.it.onNext([1,2])
    }
}


