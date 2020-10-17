//
//  DataRealm.swift
//  SoundRain
//
//  Created by Phan Hai on 06/09/2020.
//  Copyright © 2020 Phan Hai. All rights reserved.
//
import RealmSwift
import Foundation
import UIKit

extension Object {
    func toDictionary() -> [String:AnyObject] {
        let properties = self.objectSchema.properties.map { $0.name }
        var dicProps = [String:AnyObject]()
        for (key, value) in self.dictionaryWithValues(forKeys: properties) {
            //key = key.uppercased()
            if let value = value as? ListBase {
                dicProps[key] = value.toArray1() as AnyObject
            } else if let value = value as? Object {
                dicProps[key] = value.toDictionary() as AnyObject
            } else {
                dicProps[key] = value as AnyObject
            }
        }
        return dicProps
    }
}

extension ListBase {
    func toArray1() -> [AnyObject] {
        var _toArray = [AnyObject]()
        for i in 0..<self._rlmArray.count {
            let obj = unsafeBitCast(self._rlmArray[i], to: Object.self)
            _toArray.append(obj.toDictionary() as AnyObject)
        }
        return _toArray
    }
}

class MusicModelStream: Object {
     dynamic var listItem: [MusicModel] = []
}

class ExampleData: Object {
    dynamic var name = List<Int>()
}

class ExampleData2: Object {
@objc dynamic var name: String?
    @objc dynamic var age: String?
}
@objcMembers
final class LisResourceItem: Object {
    dynamic var img = ""
    dynamic var title = ""
    dynamic var resource = ""
    dynamic var url = ""
}
@objcMembers
class MyObject: Object {
    dynamic var id = 0
    dynamic var list = List<LisResourceItem>()
    override class func primaryKey() -> String? {
        return "id"
    }
}

