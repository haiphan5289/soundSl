//
//  MusicVC.swift
//  SoundRain
//
//  Created by Phan Hai on 22/08/2020.
//  Copyright © 2020 Phan Hai. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation
import RxCocoa
import RxSwift

class MusicVC: UIViewController {

    var player: AVAudioPlayer?
    private var dataSource: [MusicModel] = []
    private var collectionView: UICollectionView!
    private let disposeBag = DisposeBag()
    private var musicStream: MusicStreamIpl?
    override func viewDidLoad() {
        super.viewDidLoad()
        visualize()
        musicStream = MusicStreamIpl.init()
        setupRX()
        
    }

}
extension MusicVC {
    private func visualize() {
        dummyData()
        
        self.view.backgroundColor = .white
        
        let imgBG: UIImageView = UIImageView(frame: .zero)
        imgBG.image = UIImage(named: "img_night")
        imgBG.sizeToFit()
        imgBG.contentMode = .scaleAspectFill
        self.view.addSubview(imgBG)
        imgBG.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: (self.view.bounds.width - 30) / 2, height: 150)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(MusicCell.nib, forCellWithReuseIdentifier: MusicCell.identifier)
        
        self.view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(self.view.bounds.height * 2 / 3)
        }
        collectionView.backgroundColor = .clear
        
    }
    private func dummyData() {
        let data1: MusicModel = MusicModel(img: "img_rain_night", title: "Tiếng mưa đêm", resource: "soundRain")
        let data2: MusicModel = MusicModel(img: "img_rain_night", title: "Tiếng nước chảy và Piano", resource: "nuocchayandAudio")
        let data = [data1, data2]
        data.forEach { (v) in
            self.dataSource.append(v)
        }
    }
    func playSound() {
        guard let url = Bundle.main.url(forResource: "soundRain", withExtension: "mp3") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

            /* iOS 10 and earlier require the following line:
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */

            guard let player = player else { return }

            player.play()

        } catch let error {
            print(error.localizedDescription)
        }
    }
    private func setupRX() {
        Observable.just(dataSource)
            .bind(to: collectionView.rx.items(cellIdentifier: MusicCell.identifier, cellType: MusicCell.self)) {[weak self] (row, element, cell) in
                guard let wSelf = self else {
                    return
                }
                cell.updateUI(model: wSelf.dataSource[row])
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected.bind { (idx) in
            let vc = MusicDetail(nibName: "MusicDetail", bundle: nil)
            let text = self.dataSource[idx.row].resource ?? ""
            vc.text = text
            vc.currentIndex = idx
            self.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        
        musicStream?.dataSource.asObserver().bind(onNext: { (data) in
            print(data)
            }).disposed(by: disposeBag)
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
//                  player.delegate = self
//
//                  slideMusic.minimumValue = 0
//                  slideMusic.maximumValue = Float(player.duration)
//                  let m = Int(player.duration / 60)
//                  let s = Int(player.duration) % 60
//                  lbEnd.text = "\(m):\(s)"
                  player.play()
//                  timer = Observable<Int>.interval(RxTimeInterval.milliseconds(1000), scheduler: MainScheduler.asyncInstance)
              } catch let error {
                  print(error.localizedDescription)
              }
          }
}
