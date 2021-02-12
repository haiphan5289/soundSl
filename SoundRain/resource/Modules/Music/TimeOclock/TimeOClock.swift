//
//  TimeOClock.swift
//  SoundRain
//
//  Created by paxcreation on 10/14/20.
//  Copyright © 2020 Phan Hai. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

enum TypeTimeOClocka: Int {
    case minutes0, minutes15, minutes30, minutes45, minutes60
    
    var value: Int {
        switch  self {
        case .minutes15:
            return 15
        case .minutes30:
            return 30
        case .minutes45:
            return 45
        case .minutes60:
            return 60
        default:
            return 0
        }
    }
    var minutes: String {
        switch  self {
        case .minutes15:
            return "15 phút"
        case .minutes30:
            return "30 phút"
        case .minutes45:
            return "45 phút"
        case .minutes60:
            return "60 phút"
        default:
            return "Không giới hạn"
        }
    }
}

class TimeOClock: UIViewController {
    private let tableView: UITableView = UITableView(frame: .zero, style: .grouped)
    private var dataSource: [MusicModel] = []
    private var tap: UITapGestureRecognizer = UITapGestureRecognizer()
    private let viewTable: UIView = UIView(frame: .zero)
    private var indexSelect: Int = -1
    private var maxTimeMusic: Double = 0
    private lazy var mContainer: HeaderCornerView = {
        let v = HeaderCornerView(with: 7)
        v.containerColor = .red
        return v
    }()
    private var viewBG: UIView = UIView(frame: .zero)
    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        visualize()
        setupRX()
    }
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
}
extension TimeOClock {
    private func visualize() {
        self.view.addSubview(viewBG)
        viewBG.snp.makeConstraints { (make) in
            make.left.top.right.bottom.equalToSuperview()
        }
        viewBG.alpha = 0.2
        viewBG.addGestureRecognizer(tap)
        
        self.viewTable.backgroundColor = .white
        self.view.addSubview(self.viewTable)
        self.viewTable.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(1000)
        }
        
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        self.viewTable.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.bottom.top.right.equalToSuperview()
        }
        tableView.register(ListMusicCell.self, forCellReuseIdentifier: ListMusicCell.identifier)
        
        UIView.animate(withDuration: 0, animations: {
            self.tableView.layoutIfNeeded()
        }) { [self] (complete) in
            let maxCell = min(6, self.tableView.visibleCells.count + 1)
            var h: CGFloat = 0
            var hCell: CGFloat = 0
            
            for (index, item) in self.tableView.visibleCells.enumerated() {
                if index <= maxCell {
                    h += item.frame.size.height
                    hCell = item.frame.size.height
                } else {
                    
                }
            }
            self.viewTable.snp.updateConstraints { (make) in
                make.height.equalTo(h + hCell)
            }
            
            let rect = self.viewTable.bounds
            let ratio = min(rect.height / 200, 1)
            let v = 16 * ratio
            let benzier = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: v, height: v))
            let shape = CAShapeLayer()
            shape.frame = rect
            shape.fillColor = UIColor.blue.cgColor
            shape.path = benzier.cgPath
            self.viewTable.layer.mask = shape
            
            self.view.layoutIfNeeded()
        }
        
        
        
    }
    private func setupRX() {
        let array = Array(repeating: [1], count: 5)
        Observable.just(array)
            .bind(to: tableView.rx.items(cellIdentifier: ListMusicCell.identifier, cellType: ListMusicCell.self)) { [weak self] (row, element, cell) in
                guard let wSelf = self , let type = TypeTimeOClocka(rawValue: row) else {
                    return
                }
                cell.textLabel?.text = type.minutes
                guard row != wSelf.indexSelect else {
                    cell.textLabel?.textColor = #colorLiteral(red: 0.9333333333, green: 0.3215686275, blue: 0.1333333333, alpha: 1)
                    return
                }
                cell.textLabel?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            }.disposed(by: disposeBag)
        
        MusicStreamIpl.share.$indexTimeSelect.asObservable().bind { [weak self] (value) in
            guard let wSelf = self else {
                return
            }
            wSelf.indexSelect = value
            wSelf.tableView.reloadData()
        }.disposed(by: disposeBag)
        
        MusicStreamIpl.share.maxValueAudio.bind(onNext: weakify({ (value, wSelf) in
            wSelf.maxTimeMusic = value
            
        })).disposed(by: disposeBag)
        
        tableView.rx.itemSelected.bind(onNext: weakify({ (idx, wSelf) in
            wSelf.dismiss(animated: true) {
                guard idx.row != MusicStreamIpl.share.indexTimeSelect else {
                    MusicStreamIpl.share.indexTimeSelect = -1
                    return
                }
                MusicStreamIpl.share.timeMusicToOff = wSelf.parseTimeMusicOff(row: idx.row)
                MusicStreamIpl.share.indexTimeSelect = idx.row
            }
        })).disposed(by: disposeBag)
        
        tap.rx.event.bind { _ in
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        self.tableView.reloadData()
    }
    
    private func parseTimeMusicOff(row: Int) -> TimeInterval {
        if row == 0 {
            return 0
        }
        let date = Date()
        let timeToOff = CGFloat(row) * 15 * 60
        return Double(timeToOff) + date.timeIntervalSince1970
    }
    
}
extension TimeOClock: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v: UIView = UIView()
        let label = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.black
        label.text = "Máy hẹn giờ"
        
        v.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        return v
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
}
