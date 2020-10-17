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
    private var vPlayCurrent: UIView = UIView.init()
    private let img: UIImageView = UIImageView(frame: .zero)
    private let lbNameMusic: UILabel = UILabel.init(frame: .zero)
    private let lbTimeMusic: UILabel = UILabel.init(frame: .zero)
    private let btNextItem: UIButton = UIButton.init(frame: .zero)
    private let btPlayItem: UIButton = UIButton.init(frame: .zero)
    private var isPlayAudio: Bool = false
    private var currentIndexItem: IndexPath?
    override func viewDidLoad() {
        super.viewDidLoad()
        visualize()
        setupRX()
        MusicStreamIpl.share.setupRX()
    }
    override func viewWillAppear(_ animated: Bool) {
        MusicStreamIpl.share.maxValueAudio.bind(onNext: weakify({ (value, wSelf) in
            guard value > 0 else {
                return
            }
            
        })).disposed(by: disposeBag)
    }
    
}
extension MusicVC {
    private func visualize() {
        var hTabbar = self.tabBarController?.tabBar.frame.size.height ?? 49
        let window = UIApplication.shared.windows[0]
        let safeFrame = window.safeAreaLayoutGuide.layoutFrame
        hTabbar = window.frame.maxY - safeFrame.maxY + 49
        
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
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(hTabbar)
            make.height.equalTo(self.view.bounds.height * 2 / 3)
        }
        collectionView.backgroundColor = .red
        
        vPlayCurrent.backgroundColor = #colorLiteral(red: 0.1450980392, green: 0.137254902, blue: 0.2901960784, alpha: 1)
//        vPlayCurrent.isHidden = true
        self.view.addSubview(vPlayCurrent)
        vPlayCurrent.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(collectionView.snp.bottom)
            make.height.equalTo(70)
        }


        img.backgroundColor = .red
        self.vPlayCurrent.addSubview(img)
        img.snp.makeConstraints { (make) in
            make.left.top.equalTo(16)
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(54)
        }


        lbNameMusic.text = "Hải"
        self.vPlayCurrent.addSubview(lbNameMusic)
        lbNameMusic.snp.makeConstraints { (make) in
            make.top.equalTo(img)
            make.left.equalTo(img.snp.right).inset(-16)
        }


        lbTimeMusic.text = "99:99"
        self.vPlayCurrent.addSubview(lbTimeMusic)
        lbTimeMusic.snp.makeConstraints { (make) in
            make.bottom.equalTo(img)
            make.left.equalTo(img.snp.right).inset(-16)
        }


        btNextItem.setImage(UIImage(named: "ic_next"), for: .normal)
        self.vPlayCurrent.addSubview(btNextItem)
        btNextItem.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(16)
            make.width.height.equalTo(54)
            make.centerY.equalToSuperview()
        }

        btPlayItem.setImage(UIImage(named: "ic_next"), for: .normal)
        self.vPlayCurrent.addSubview(btPlayItem)
        btPlayItem.snp.makeConstraints { (make) in
            make.right.equalTo(self.btNextItem.snp.left).inset(-16)
            make.width.height.equalTo(54)
            make.centerY.equalToSuperview()
        }
        
    }
    private func setupRX() {
        MusicStreamIpl.share.listsc
            .bind(to: collectionView.rx.items(cellIdentifier: MusicCell.identifier, cellType: MusicCell.self)) { (row, element, cell) in
                cell.updateUI(model: element)
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected.bind { (idx) in
            let vc = MusicDetail(nibName: "MusicDetail", bundle: nil)
            vc.currentIndex = idx
            vc.delegate = self
            self.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        
        btNextItem.rx.tap.bind(onNext: weakify({ (wSelf) in
            guard var nextItem = self.currentIndexItem else {
                return
            }
            nextItem.row += 1
            MusicStreamIpl.share.getIndex(idx: nextItem)
        })).disposed(by: disposeBag)
        
        btPlayItem.rx.tap.map { (_) -> Bool in
            return self.isPlayAudio
        }.bind(onNext: weakify({ (isPlay, wSelf) in
            guard isPlay else {
                wSelf.btPlayItem.setImage(UIImage(named: "ic_resume"), for: .normal)
                MusicStreamIpl.share.playingAudio()
                return
            }
            wSelf.btPlayItem.setImage(UIImage(named: "ic_play"), for: .normal)
            MusicStreamIpl.share.stopAudio()
        })).disposed(by: disposeBag)
        
        MusicStreamIpl.share.isPlaying.bind(onNext: weakify({ (isPlay, wSelf) in
            guard isPlay else {
                wSelf.btPlayItem.setImage(UIImage(named: "ic_resume"), for: .normal)
                return
            }
            wSelf.btPlayItem.setImage(UIImage(named: "ic_play"), for: .normal)
            
        })).disposed(by: disposeBag)
        
        let item = MusicStreamIpl.share.item
        let idx = MusicStreamIpl.share.currentIndexItem
        let d = MusicStreamIpl.share.listsc
        let isPlayAudio = MusicStreamIpl.share.isPlaying
        
        Observable.combineLatest(item, idx, d, isPlayAudio).bind { [weak self] (item, idx, datas, isPlay) in
            guard let wSelf = self else {
                return
            }
            wSelf.vPlayCurrent.isHidden = false
            wSelf.img.loadhinh(link: item.img ?? "")
            wSelf.lbNameMusic.text = item.title ?? ""
            wSelf.currentIndexItem = idx
            wSelf.isPlayAudio = isPlay
            
            guard idx?.row == datas.count - 1 else {
                wSelf.btNextItem.isEnabled = true
                return
            }
            wSelf.btNextItem.isEnabled = false
        }.disposed(by: disposeBag)
        
        MusicStreamIpl.share.currentTime.bind(onNext: weakify({ (time, wSelf) in
            let m = Int(time / 60)
            let s = Int(time) % 60
            wSelf.lbTimeMusic.text = "\(m):\(s)"
            })).disposed(by: disposeBag)
        
    }
}
extension MusicVC: MusicDetailDelegate {
    func callBack() {
    }
}
struct Student {
    var score: BehaviorSubject<Int>
}
