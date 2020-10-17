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
    var listsc: Observable<[MusicModel]> { get }
    var item: Observable<MusicModel> { get }
    var currentIndexItem: Observable<IndexPath?> { get }
    var isPlaying: Observable<Bool> { get }
    var isEndAudio: Observable<Bool> { get }
    var currentTime: Observable<TimeInterval> { get }
    var maxValueAudio: Observable<Double> { get }
}
final class MusicStreamIpl: MusicStream {
    var listsc: Observable<[MusicModel]> {
        return self.$listSource.asObservable()
    }
    
    public static var share = MusicStreamIpl()
    var item: Observable<MusicModel> {
        return self.$itemOb
    }
    var currentIndexItem: Observable<IndexPath?> {
        return self.$currentIndex.asObservable()
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
    var maxValueAudio: Observable<Double> {
        return self.$maxValueSlider
    }
    @Replay(queue: MainScheduler.asyncInstance) private var itemOb: MusicModel
    private var itemCurrent: MusicModel?
    @VariableReplay var currentIndex: IndexPath?
    @Replay(queue: MainScheduler.asyncInstance) private var isPlay: Bool
    @Replay(queue: MainScheduler.asyncInstance) var isEndAudioObser: Bool
    @Replay(queue: MainScheduler.asyncInstance) private var mCurrentTime: TimeInterval
    @Replay(queue: MainScheduler.asyncInstance) private var maxValueSlider: Double
    @Replay(queue: MainScheduler.asyncInstance) private var itemCovert: MusicModel
    let timer = Observable<Int>.interval(RxTimeInterval.milliseconds(1000), scheduler: MainScheduler.asyncInstance)
    @VariableReplay var timeMusicToOff: CGFloat = 0
    @VariableReplay private var listSource: [MusicModel] = []
    @VariableReplay var indexTimeSelect: Int = -1
    private var mCurrentIndex: IndexPath?
    var dataSource: BehaviorSubject<[MusicModel]> = BehaviorSubject.init(value: [])
    private var listMusiceFavourite: BehaviorRelay<[MusicModel]> = BehaviorRelay.init(value: [])
    private var listLoved: [MusicModel] = []
    var audio: AVAudioPlayer?
    private let disposeBag = DisposeBag()
}

extension MusicStreamIpl {
    private func dummyData() {
        let realm = try! Realm()
        let listCount = realm.objects(MyObject.self)
        guard listCount.count <= 0 else {
            self.getMusicRealm(objects: listCount)
            return
        }
        self.getMusicFirebase()
    }
    private func getMusicRealm(objects: Results<MyObject>) {
        objects.first?.list.forEach({ (item) in
            do {
                let data = try JSONSerialization.data(withJSONObject: item.toDictionary(), options: .prettyPrinted)
                let model = try JSONDecoder().decode(MusicModel.self, from: data)
                self.listSource.append(model)
            } catch let err {
                print(err.localizedDescription)
            }
        })
        
    }
    private func getMusicFirebase() {
        var data: [MusicModel] = []
        let dataBase = Database.database().reference()
        dataBase.child("\(FirebaseTable.sound.table)").observe(.childAdded) { (snapShot) in
            if let user = self.convertDataSnapshotToCodable(data: snapShot, type: MusicModel.self) {
//                var item = user
//                self.getUrl(item: item) { (txtUrl) in
//                    item.url = txtUrl
//                    data.append(item)
//                    self.dataSource.onNext(data)
//                }
                self.itemCovert = user
                data.append(user)
                self.dataSource.onNext(data)
            }
        }
    }
    func setupRX() {
        dummyData()
        
        self.listMusiceFavourite.asObservable().bind { (value) in
            self.listLoved = value
        }.disposed(by: disposeBag)
        
        let isEndAudio = self.$isEndAudioObser
        let typeTime = self.$indexTimeSelect
        let timeOff = self.$timeMusicToOff
            
        Observable.combineLatest(timer, isEndAudio, typeTime, timeOff).bind { [weak self] (current, isEnd, time, timeOff) in
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
            
            guard time != -1 else {
                return
            }
            
            guard time != 0 else {
                return
            }
            
            guard CGFloat(current) < timeOff else {
                wSelf.audio?.pause()
                return
            }
            
        }.disposed(by: disposeBag)
        
        let item = self.$itemCovert.flatMap { (item) -> Observable<MusicModel> in
            return Observable.create { (observe) -> Disposable in
                guard  let text = item.url, let url = URL(string: text) else {
                    return Disposables.create()
                }
                
                var t = item
                
                let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                    var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    documentsURL.appendPathComponent("file.csv")
                    return (documentsURL, [.removePreviousFile])
                }
                
                Alamofire.download(url, to: destination).responseData { response in
                    guard let url = response.destinationURL else {
                        return
                    }
                    t.url = url.absoluteString
                    observe.onNext(t)
                }
                return Disposables.create()
            }
        }
        
        Observable.combineLatest(item, self.dataSource).map { (item, list) -> [MusicModel] in
            var l = list
            for (index, i) in list.enumerated() where i.img == item.img {
                l[index] = item
            }
            return l
        }.bind { (list) in
            guard self.listSource.count > 0 else {
                self.listSource = list
                return
            }
            var t = self.listSource
            
            for (index1, item) in list.enumerated() {
                for (index, item2) in self.listSource.enumerated() {
                    if let isContent = item.url?.contains("file.csv"), isContent, item.url != item2.url && index == index1 {
                        t[index] = item
                    }
                }
            }
            self.listSource = t
            
        }.disposed(by: disposeBag)
        
        self.$listSource
            .filter { $0.count > 0 }
            .debounce(.milliseconds(100), scheduler: ConcurrentDispatchQueueScheduler.init(qos: .background))
            .asObservable().bind { (list) in
                let realm = try! Realm()
                let l = MyObject()
                list.forEach { (item) in
                    let t = LisResourceItem()
                    t.img = item.img ?? ""
                    t.resource = item.resource ?? ""
                    t.title = item.title ?? ""
                    t.url = item.url ?? ""
                    l.list.append(t)
                }
                do {
                    try realm.write {
                        realm.add(l, update: .all)
                    }
                } catch let err {
                    print(err.localizedDescription)
                }
        }.disposed(by: disposeBag)
        
        self.$currentIndex.asObservable()
            .distinctUntilChanged()
            .bind { [weak self] (idx) in
                guard let wSelf = self, let idx = idx else {
                    return
                }
                let item = wSelf.listSource[idx.row]
                wSelf.itemOb = item
                wSelf.itemCurrent = item
                wSelf.mCurrentIndex = idx
                guard let check = item.url, let url = URL(string: check) else {
                    return
                }
                wSelf.play(url: url)
                
            }
        .disposed(by: disposeBag)
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
    func getIndex(idx: IndexPath) {
        
        guard self.currentIndex != idx else {
            return
        }
        let item = self.listSource[idx.row]
        self.itemOb = item
        self.itemCurrent = item
        self.currentIndex = idx
        self.mCurrentIndex = idx
        guard let check = item.url, let url = URL(string: check) else {
            return
        }
        self.play(url: url)
    }
    
    private func getUrl(item: MusicModel, onCompletion: @escaping (_ requestURL: String) -> Void)  {
        guard  let text = item.url, let url = URL(string: text) else {
            return
        }
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            documentsURL.appendPathComponent("file.csv")
            return (documentsURL, [.removePreviousFile])
        }
        
        Alamofire.download(url, to: destination).responseData { response in
            guard let url = response.destinationURL else {
                return
            }
            onCompletion(url.absoluteString)
        }
    }
    func play(url:URL) {
        do {
            self.audio = try AVAudioPlayer(contentsOf: url)
            audio?.prepareToPlay()
            audio?.play()
            self.isPlay = true
            guard let max = audio?.duration else {
                return
            }
            self.maxValueSlider = max
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


