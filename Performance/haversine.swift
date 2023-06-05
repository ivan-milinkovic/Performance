//
//  haversine.swift
//  Performance
//
//  Created by Ivan Milinkovic on 3.6.23..
//

import Foundation

private let fileUrl = dataDirUrl.appending(path: "coords.json", directoryHint: URL.DirectoryHint.notDirectory)

//func createCoords() {
//    let count = 1_000_000
//    var a = [[String : Double]]()
//    a.reserveCapacity(count)
//    for _ in 0..<count {
//        let lon1 = Double.random(in: -180.0...180.0)
//        let lat1 = Double.random(in: -90.0...90.0)
//        let lon2 = Double.random(in: -180.0...180.0)
//        let lat2 = Double.random(in: -90.0...90.0)
//        a.append( ["lon1" : lon1, "lat1" : lat1, "lon2" : lon2, "lat2" : lat2] )
//    }
//    let data = try! JSONSerialization.data(withJSONObject: a)
//    try! data.write(to: fileUrl)
//}


func testHaversine() {
    let starttime = Date()
    
    let jsonData = try! Data.init(contentsOf: fileUrl)
    let coords = try! JSONDecoder().decode([[String: Double]].self, from: jsonData)
    
    let midtime = Date()
    
    let r = 6371.0
    var avg = 0.0
    var i = 0
    while i < coords.count {
        let entry = coords[i]
        avg += haversine(lon1: entry["lon1"]!,
                         lat1: entry["lat1"]!,
                         lon2: entry["lon2"]!,
                         lat2: entry["lat2"]!,
                         r: r)
        i += 1
    }
    avg /= Double(coords.count)
    let endtime = Date()
    
    print("load:", timeString(midtime.timeIntervalSince(starttime)))
    print("calc:", timeString(endtime.timeIntervalSince(midtime)))
    print("total:", timeString(endtime.timeIntervalSince(starttime)))
}

private func haversine(lon1: Double, lat1: Double, lon2: Double, lat2: Double, r: Double) -> Double {
    let term = pow(sin((lat2 - lat1) / 2.0), 2) + cos(lat1) * pow(sin((lon2 - lon1) / 2), 2)
    return 2 * r * asin(sqrt(term))
}
