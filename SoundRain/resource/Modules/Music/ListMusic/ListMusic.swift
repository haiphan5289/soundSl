//
//  ListMusic.swift
//  SoundRain
//
//  Created by Phan Hai on 02/09/2020.
//  Copyright © 2020 Phan Hai. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import GoogleMobileAds

protocol ListMusicDelegate {
    func selectIndex(index: IndexPath)
}

class ListMusic: UIViewController {

    private var interstitial: GADInterstitial!
    
    private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
    private var dataSource: [MusicModel] = []
    private var tap: UITapGestureRecognizer = UITapGestureRecognizer()
    private var viewBG: UIView = UIView(frame: .zero)
    private let disposeBag = DisposeBag()
    var delegate: ListMusicDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        visualize()
        setupRX()
    }

}
extension ListMusic {
    private func visualize() {
        self.view.addSubview(viewBG)
        viewBG.snp.makeConstraints { (make) in
            make.left.top.right.bottom.equalToSuperview()
        }
        viewBG.addGestureRecognizer(tap)
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(200)
        }
//        let rect = CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: 200))
//           let benzier = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 16, height: 16))
//           let shape = CAShapeLayer()
//           shape.frame = rect
//           shape.fillColor = UIColor.blue.cgColor
//           shape.path = benzier.cgPath
//           tableView.layer.mask = shape
        tableView.delegate = self
        tableView.register(ListMusicCell.self, forCellReuseIdentifier: ListMusicCell.identifier)
        
        self.interstitial = GADInterstitial(adUnitID: AdModId.share.interstitialID)
        let request = GADRequest()
        self.interstitial.load(request)
        self.interstitial.delegate = self
        
    }
    private func setupRX() {
//        MusicStreamIpl.share.listsc.asObservable().bind(onNext: weakify({ (listData, wSelf) in
//            wSelf.dataSource = listData
//            wSelf.tableView.reloadData()
//            })).disposed(by: disposeBag)
        
        MusicStreamIpl.share.listsc
             .bind(to: tableView.rx.items(cellIdentifier: ListMusicCell.identifier, cellType: ListMusicCell.self)) { (row, element, cell) in
                cell.textLabel?.text = element.title
         }.disposed(by: disposeBag)
         
         tableView.rx.itemSelected.bind(onNext: weakify({ (idx, wSelf) in
            wSelf.dismiss(animated: true) {
                wSelf.delegate?.selectIndex(index: idx)
            }
         })).disposed(by: disposeBag)
        
        tap.rx.event.bind { _ in
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }
}
extension ListMusic: UITableViewDelegate {

}
extension ListMusic: GADInterstitialDelegate {
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        interstitial.present(fromRootViewController: self)
    }
}
