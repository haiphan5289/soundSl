//
//  MusicDetail.swift
//  SoundRain
//
//  Created by Phan Hai on 23/08/2020.
//  Copyright © 2020 Phan Hai. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

final class MusicDetail: UIViewController {
    
    var data: MusicModel?
    var player: AVAudioPlayer?
    @IBOutlet weak var lbStart: UILabel!
    @IBOutlet weak var btPause: UIButton!
    @IBOutlet weak var btReplay: UIButton!
    @IBOutlet weak var slideMusic: UISlider!
    @IBOutlet weak var lbEnd: UILabel!
    @IBOutlet weak var btListMusic: UIButton!
    @IBOutlet weak var btPrevious: UIButton!
    @IBOutlet weak var btNext: UIButton!
    @IBOutlet weak var btLoved: UIButton!
    
    private var musicStream: MusicStreamIpl = MusicStreamIpl.init()
    private var dataSource: [MusicModel] = []
    private var isEndAudio: PublishSubject<Bool> = PublishSubject.init()
    var currentIndex: IndexPath = IndexPath(row: 0, section: 0)
    private var timer: Observable<Int>?
    private let disposeBag = DisposeBag()
    private var isReplay: Bool = false
    var text: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        slideMusic.maximumValue = 10
        slideMusic.value = 0
        timer = Observable<Int>.interval(RxTimeInterval.milliseconds(1000), scheduler: MainScheduler.asyncInstance)
        setupRX()
//        self.playSound(text: text)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        //         let navigationBar = navigationController?.navigationBar
        //          navigationBar?.layoutIfNeeded()
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white,
                                                                        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18.0, weight: .bold) ]
        //         navigationBar?.barTintColor = .clear
        //        navigationBar?.shadowImage = UIImage()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        title = "Tiêng mưa"
    }
    override func viewWillDisappear(_ animated: Bool) {
        player?.pause()
    }
}
extension MusicDetail {
        func playIndexItem(idx: IndexPath) {

            let itemPlay = dataSource[idx.row]
            self.playSound(text: itemPlay.resource ?? "")
            self.updateUIBUtton(idx: idx)
        }
        
        func playSound(text: String) {
            guard let url = Bundle.main.url(forResource: text, withExtension: "mp3") else { return }
    
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
    
                /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
                player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
    
                /* iOS 10 and earlier require the following line:
                player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
    
                guard let player = player else { return }
    
                player.pause()
                player.delegate = self

                slideMusic.minimumValue = 0
                slideMusic.maximumValue = Float(player.duration)
                let m = Int(player.duration / 60)
                let s = Int(player.duration) % 60
                lbEnd.text = "\(m):\(s)"
                player.play()
                timer = Observable<Int>.interval(RxTimeInterval.milliseconds(1000), scheduler: MainScheduler.asyncInstance)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    private func setupRX() {
        timer?.bind(onNext: { [weak self] (value) in
            guard let wSelf = self, let current = wSelf.musicStream.audio?.currentTime else {
                return
            }
            wSelf.slideMusic.value = Float(CGFloat(current))
            let m = Int(current / 60)
            let s = Int(current) % 60
            wSelf.lbStart.text = "\(m):\(s)"
            
//            guard current == wSelf.musicStream.audio?.duration  else {
//                wSelf.slideMusic.value = Float(CGFloat(current))
//                return
//            }
//            print("\(wSelf.slideMusic.value) ===== \(current) ====== \(wSelf.slideMusic.maximumValue)")
//
//            guard !wSelf.isReplay else {
//                wSelf.player?.pause()
//                return
//            }
//
//            wSelf.slideMusic.value = 0
//            current = 0
//            wSelf.player?.play()
        }).disposed(by: disposeBag)
        
        isEndAudio.asObserver().bind(onNext: weakify({ (isEnd, wSelf) in
            guard isEnd else {
                return
            }
            
            guard wSelf.isReplay else {
                wSelf.musicStream.audio?.pause()
                return
            }
            wSelf.musicStream.audio?.play()
        })).disposed(by: disposeBag)
        
//        NotificationCenter.default.rx.notification(NSNotification.Name.AVPlayerItemDidPlayToEndTime).bind { (isNo) in
//            print(isNo)
//        }.disposed(by: disposeBag)
        
        
//        NotificationCenter.default.addObserver(self, selector: Selector(("playerDidFinishPlaying:")),
//               name: NSNotification.Name.AVAudio, object: player?.currentTime)
//
//        func playerDidFinishPlaying(note: NSNotification) {
//            print("Video Finished")
//        }
        
        self.musicStream.maxValueSlider.asObserver().bind { [weak self] (value) in
            guard let wSelf = self else {
                return
            }
            wSelf.slideMusic.maximumValue = Float(value)
            wSelf.musicStream.audio?.delegate = self
            let m = Int(value / 60)
            let s = Int(value) % 60
            wSelf.lbEnd.text = "\(m):\(s)"
        }.disposed(by: disposeBag)
        
        slideMusic.rx.value.bind { [weak self](value) in
            guard let wSelf = self else {
                return
            }
            wSelf.musicStream.audio?.pause()
            wSelf.musicStream.audio?.currentTime = TimeInterval(value)
            wSelf.musicStream.audio?.play()
        }.disposed(by: disposeBag)
        
        self.btPause.rx.tap.bind(onNext: weakify { wSelf in
            if wSelf.btPause.isSelected {
                wSelf.btPause.isSelected = false
                wSelf.player?.play()
            } else {
                wSelf.btPause.isSelected = true
                wSelf.player?.pause()
            }
        }).disposed(by: disposeBag)
        
        btReplay.rx.tap.bind(onNext: weakify { wSelf in
            if wSelf.btReplay.isSelected {
                wSelf.btReplay.isSelected = false
                wSelf.isReplay = false
                wSelf.btReplay.setImage(UIImage(named: "ic_replay"), for: .normal)
            } else {
                wSelf.btReplay.isSelected = true
                wSelf.isReplay = true
                wSelf.btReplay.setImage(UIImage(named: "ic_replay_selected"), for: .selected)
            }
        }).disposed(by: disposeBag)
        
        btListMusic.rx.tap.bind { _ in
            let vc = ListMusic()
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }.disposed(by: disposeBag)

//        musicStream.dataSource.asObserver().bind(onNext: weakify({ (data, wSelf) in
//            wSelf.dataSource = data
////            wSelf.playSound(text: data[wSelf.currentIndex.row].resource ?? "")
//            wSelf.updateUIBUtton(idx: wSelf.currentIndex)
//            guard let firstItem = data.first, let resource = firstItem.url else {
//                return
//            }
//            wSelf.musicStream.playSound(text: resource)
//            })).disposed(by: disposeBag)
        
        btPrevious.rx.tap.bind(onNext: weakify({ (wSelf) in
            switch wSelf.currentIndex.row {
            case 0:
                break
            default:
                wSelf.currentIndex.row -= 1
            }
            wSelf.playIndexItem(idx: wSelf.currentIndex)
            })).disposed(by: disposeBag)
        
        btNext.rx.tap.bind(onNext: weakify({ (wSelf) in
            switch wSelf.currentIndex.row {
            case self.dataSource.count - 1:
                break
            default:
                wSelf.currentIndex.row += 1
            }
//        let idx = IndexPath(row: wSelf.currentIndex.row + 1, section: wSelf.currentIndex.section)
            wSelf.playIndexItem(idx: wSelf.currentIndex)
        })).disposed(by: disposeBag)
        
        btLoved.rx.tap.bind(onNext: weakify({ (wSelf) in
            let item = wSelf.dataSource[wSelf.currentIndex.row]
            if wSelf.btLoved.isSelected {
                wSelf.musicStream.removeListLove(item: item)
                wSelf.btLoved.setTitle("Thêm vào", for: .normal)
                  wSelf.btLoved.isSelected = false
            } else {
              wSelf.musicStream.updateListLove(item: item)
                wSelf.btLoved.setTitle("Đã thêm", for: .selected)
                wSelf.btLoved.isSelected = true
            }
            
            })).disposed(by: disposeBag)
        
        self.playItem()
        
    }
    private func playItem() {
        self.musicStream.getIndex(idx: self.currentIndex)
    }
}
extension MusicDetail: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isEndAudio.onNext(flag)
//        print(flag)
//        if isReplay {
//            self.player?.pause()
//            self.player?.play()
//        }
    }
}
extension MusicDetail: ListMusicDelegate {
    func selectIndex(index: IndexPath) {
        let text = self.dataSource[index.row].resource ?? ""
        self.playSound(text: text)
        self.updateUIBUtton(idx: index)
    }
    private func updateMusic() {
        slideMusic.value = 0
        slideMusic.maximumValue = 1000
        lbEnd.text = String(1000)
        
        self.view.layoutIfNeeded()
    }
    private func updateUIBUtton(idx: IndexPath) {
        switch idx.row {
        case 0:
            self.btPrevious.isEnabled = false
            self.btNext.isEnabled = true
        case self.dataSource.count - 1:
            self.btPrevious.isEnabled = true
            self.btNext.isEnabled = false
        default:
            self.btPrevious.isEnabled = true
            self.btNext.isEnabled = true
        }
    }
}
