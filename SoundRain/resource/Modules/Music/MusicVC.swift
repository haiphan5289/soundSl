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
    private var vPlayCurrent: UIView = UIView.init()
    override func viewDidLoad() {
        super.viewDidLoad()
        visualize()
        musicStream = MusicStreamIpl.init()
        setupRX()
//        let ryan = Student(score: BehaviorSubject(value: 80))
//        let charlotte = Student(score: BehaviorSubject(value: 90))

//        // 3
//        let student = PublishSubject<Student>()
//
//        // 4
//        student.asObserver()
//               .flatMap {
//                     $0.score
//                }
//                // 5
//                .subscribe(onNext: {
//                     print($0)
//                 })
//                .dispose()
//
//        // 6
//        student.map { (stu) -> Observable<Int> in
//            return stu.score
//        }.bind { (value) in
//            print(value)
//        }.disposed(by: disposeBag)
//
//        student.onNext(ryan)
//        ryan.score.onNext(85)
//        student.onNext(charlotte)
//        charlotte.score.onNext(95)
    }

}
extension MusicVC {
    private func visualize() {
        let hTabBar: Int = Int(self.tabBarController?.tabBar.frame.height ?? 0)
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
            make.bottom.equalToSuperview().inset(hTabBar)
            make.height.equalTo(self.view.bounds.height * 2 / 3)
        }
        collectionView.backgroundColor = .red
        
        vPlayCurrent.backgroundColor = #colorLiteral(red: 0.1450980392, green: 0.137254902, blue: 0.2901960784, alpha: 1)
        self.view.addSubview(vPlayCurrent)
        vPlayCurrent.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(collectionView.snp.bottom)
            make.height.equalTo(70)
        }
        
        let img: UIImageView = UIImageView(frame: .zero)
        img.backgroundColor = .red
        self.vPlayCurrent.addSubview(img)
        img.snp.makeConstraints { (make) in
            make.left.top.equalTo(16)
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(54)
        }
        
        let lbNameMusic: UILabel = UILabel.init(frame: .zero)
        lbNameMusic.text = "Hải"
        self.vPlayCurrent.addSubview(lbNameMusic)
        lbNameMusic.snp.makeConstraints { (make) in
            make.top.equalTo(img)
            make.left.equalTo(img.snp.right).inset(-16)
        }
        
        let lbTimeMusic: UILabel = UILabel.init(frame: .zero)
        lbTimeMusic.text = "10:00"
        self.vPlayCurrent.addSubview(lbTimeMusic)
        lbTimeMusic.snp.makeConstraints { (make) in
            make.bottom.equalTo(img)
            make.left.equalTo(img.snp.right).inset(-16)
        }
        
        let btPlay: UIButton = UIButton.init(frame: .zero)
        btPlay.backgroundColor = .red
        self.vPlayCurrent.addSubview(btPlay)
        btPlay.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(16)
            make.width.height.equalTo(54)
            make.centerY.equalToSuperview()
        }
        
    }
    private func setupRX() {
        musicStream?.dataSource.asObserver()
            .bind(to: collectionView.rx.items(cellIdentifier: MusicCell.identifier, cellType: MusicCell.self)) { (row, element, cell) in
                cell.updateUI(model: element)
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected.bind { (idx) in
            let vc = MusicDetail(nibName: "MusicDetail", bundle: nil)
            vc.currentIndex = idx
            self.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: disposeBag)
        
        
    }
}
struct Student {
    var score: BehaviorSubject<Int>
}
