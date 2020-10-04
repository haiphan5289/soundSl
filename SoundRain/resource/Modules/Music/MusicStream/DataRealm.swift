//
//  DataRealm.swift
//  SoundRain
//
//  Created by Phan Hai on 06/09/2020.
//  Copyright © 2020 Phan Hai. All rights reserved.
//
import RealmSwift
import UIKit

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
    dynamic var name: List<LisResourceItem> = List()
}
