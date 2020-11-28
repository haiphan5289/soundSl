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

protocol MusicDetailDelegate {
    func callBack()
}

final class MusicDetail: UIViewController {
    
    var data: MusicModel?
    var player: AVAudioPlayer?
    var delegate: MusicDetailDelegate?
    @IBOutlet weak var lbStart: UILabel!
    @IBOutlet weak var btPause: UIButton!
    @IBOutlet weak var btReplay: UIButton!
    @IBOutlet weak var slideMusic: UISlider!
    @IBOutlet weak var lbEnd: UILabel!
    @IBOutlet weak var btListMusic: UIButton!
    @IBOutlet weak var btPrevious: UIButton!
    @IBOutlet weak var btNext: UIButton!
    @IBOutlet weak var btLoved: UIButton!
    private var isPlayAudio: Bool = false
    private var dataSource: [MusicModel] = []
    private var isEndAudio: PublishSubject<Bool> = PublishSubject.init()
    var currentIndex: IndexPath = IndexPath(row: 0, section: 0)
    private let disposeBag = DisposeBag()
    private var isReplay: Bool = false
    var text: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        slideMusic.maximumValue = 10
        slideMusic.value = 0
        setupRX()
        MusicStreamIpl.share.currentIndex = currentIndex
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
        
        let buttonLeft = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 44, height: 44)))
        buttonLeft.setTitle("Hẹn giờ", for: .normal)
        buttonLeft.setTitleColor(.white, for: .normal)
        buttonLeft.contentEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
        let leftBarButton = UIBarButtonItem(customView: buttonLeft)
        navigationItem.rightBarButtonItem = leftBarButton
        
        buttonLeft.rx.tap.bind { _ in
            let vc = TimeOClock(nibName: "TimeOClock", bundle: nil)
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        player?.pause()
        self.delegate?.callBack()
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
        } catch let error {
            print(error.localizedDescription)
        }
    }
    private func setupRX() {
        MusicStreamIpl.share.isEndAudioObser = false
        
        MusicStreamIpl.share.currentTime.bind(onNext: weakify({ (value, wSelf) in
            guard let current = MusicStreamIpl.share.audio?.currentTime else {
                return
            }
            wSelf.slideMusic.value = Float(CGFloat(current))
            let m = Int(current / 60)
            let s = Int(current) % 60
            wSelf.lbStart.text = String(format: "%d:%d", m, s)
        })).disposed(by: disposeBag)
        
//        isEndAudio.asObserver().bind(onNext: weakify({ (isEnd, wSelf) in
//            guard isEnd else {
//                return
//            }
//            
//            guard wSelf.isReplay else {
//                MusicStreamIpl.share.audio?.pause()
//                return
//            }
//            MusicStreamIpl.share.audio?.play()
//        })).disposed(by: disposeBag)
        
        MusicStreamIpl.share.maxValueAudio.bind { [weak self] (value) in
            guard let wSelf = self else {
                return
            }
            wSelf.slideMusic.maximumValue = Float(value)
            MusicStreamIpl.share.audio?.delegate = self
            let m = Int(value / 60)
            let s = Int(value) % 60
            wSelf.lbEnd.text = "\(m):\(s)"
        }.disposed(by: disposeBag)
        
        slideMusic.rx.value.bind { (value) in
            guard value > 0 else {
                return
            }
            MusicStreamIpl.share.isEndAudioObser = false
            MusicStreamIpl.share.audio?.pause()
            MusicStreamIpl.share.audio?.currentTime = TimeInterval(value)
            MusicStreamIpl.share.audio?.play()
            print(value)
        }.disposed(by: disposeBag)
        
        MusicStreamIpl.share.isPlaying.bind(onNext: weakify({ (isPlay, wSelf) in
            wSelf.isPlayAudio = isPlay
            guard isPlay else {
                wSelf.btPause.setTitle("Đang dừng", for: .normal)
                return
            }
            wSelf.btPause.setTitle("Đang nghe", for: .normal)
        })).disposed(by: disposeBag)
        
        btPause.rx.tap.map { return self.isPlayAudio
        }.bind(onNext: weakify({ (isPlay, wSelf) in
            guard isPlay else {
                wSelf.btPause.setTitle("Đang dừng", for: .normal)
                MusicStreamIpl.share.playingAudio()
                return
            }
            wSelf.btPause.setTitle("Đang nghe", for: .normal)
            MusicStreamIpl.share.stopAudio()
        })).disposed(by: disposeBag)
        
        self.btPause.rx.tap.bind(onNext: weakify { wSelf in
            if wSelf.btPause.isSelected {
                wSelf.btPause.isSelected = false
                MusicStreamIpl.share.playingAudio()
                wSelf.btPause.setTitle("Đang dừng", for: .normal)
            } else {
                wSelf.btPause.setTitle("Đang nghe", for: .normal)
                wSelf.btPause.isSelected = true
                MusicStreamIpl.share.stopAudio()
            }
        }).disposed(by: disposeBag)
        
        btReplay.rx.tap.bind(onNext: weakify { wSelf in
            if wSelf.btReplay.isSelected {
                wSelf.btReplay.isSelected = false
                wSelf.isReplay = false
                MusicStreamIpl.share.isReplay.onNext(false)
                wSelf.btReplay.setTitle("Lặp lại", for: .normal)
            } else {
                wSelf.btReplay.isSelected = true
                wSelf.isReplay = true
                MusicStreamIpl.share.isReplay.onNext(true)
                wSelf.btReplay.setTitle("Không lặp lại", for: .normal)
            }
        }).disposed(by: disposeBag)
        
        btListMusic.rx.tap.bind { _ in
            let vc = ListMusic()
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
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
            wSelf.playIndexItem(idx: wSelf.currentIndex)
        })).disposed(by: disposeBag)
        
        btLoved.rx.tap.bind(onNext: weakify({ (wSelf) in
            let item = wSelf.dataSource[wSelf.currentIndex.row]
            if wSelf.btLoved.isSelected {
                MusicStreamIpl.share.removeListLove(item: item)
                wSelf.btLoved.setTitle("Thêm vào", for: .normal)
                wSelf.btLoved.isSelected = false
            } else {
                MusicStreamIpl.share.updateListLove(item: item)
                wSelf.btLoved.setTitle("Đã thêm", for: .selected)
                wSelf.btLoved.isSelected = true
            }
            
        })).disposed(by: disposeBag)
        
        MusicStreamIpl.share.item.bind { (item) in
            self.title = item.title
        }.disposed(by: disposeBag)
        
    }
    
    @objc func playerDidFinishPlaying(){
        print("Video Finished")
    }
}
extension MusicDetail: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isEndAudio.onNext(flag)
        MusicStreamIpl.share.isEndAudioObser = flag
    }
}
extension MusicDetail: ListMusicDelegate {
    func selectIndex(index: IndexPath) {
//        let text = MusicStreamIpl [index.row].resource ?? ""
        MusicStreamIpl.share.currentIndex = index
//        self.playSound(text: text)
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
