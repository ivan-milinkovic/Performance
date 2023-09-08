import Foundation

//private let fileUrl = dataDirUrl.appending(path: "coords_1_000.json", directoryHint: URL.DirectoryHint.notDirectory)
private let fileUrl = dataDirUrl.appending(path: "coords_10_000.json", directoryHint: URL.DirectoryHint.notDirectory)
//private let fileUrl = dataDirUrl.appending(path: "coords_1_000_000.json", directoryHint: URL.DirectoryHint.notDirectory)

func createCoords() {
    let count = 10_000
    var a = [[String : Double]]()
    a.reserveCapacity(count)
    for _ in 0..<count {
        let lon1 = Double.random(in: -180.0...180.0)
        let lat1 = Double.random(in: -90.0...90.0)
        let lon2 = Double.random(in: -180.0...180.0)
        let lat2 = Double.random(in: -90.0...90.0)
        a.append( ["lon1" : lon1, "lat1" : lat1, "lon2" : lon2, "lat2" : lat2] )
    }
    let data = try! JSONSerialization.data(withJSONObject: a)
    try! data.write(to: fileUrl)
}


func testHaversine() {
    
//    createCoords()
//    return;
    
//    let t = mach_absolute_time() - t0
    
    let starttime = Date()
    let startTicks = mach_absolute_time()
    
//    let jsonData = try! Data.init(contentsOf: fileUrl)
//    let coords = try! JSONDecoder().decode([[String: Double]].self, from: jsonData)
    
//    var jsonStr = String(data: try! Data.init(contentsOf: fileUrl), encoding: .utf8)!
    var jsonStr = try! String(contentsOf: fileUrl)
    jsonStr.makeContiguousUTF8()
    let coords = JsonParserUnicode().parse(jsonString: jsonStr) as! [[String: Double]]
    
    let midtime = Date()
    let midTicks = mach_absolute_time()
    
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
    let endTicks = mach_absolute_time()
    
    print("load:\t\(timeString(midtime.timeIntervalSince(starttime))),\t\(midTicks - startTicks) ticks")
    print("calc:\t\(timeString(endtime.timeIntervalSince(midtime))),\t\t\(endTicks - midTicks) ticks")
    print("total:\t\(timeString(endtime.timeIntervalSince(starttime))),\t\(endTicks - startTicks) ticks")
}

private func haversine(lon1: Double, lat1: Double, lon2: Double, lat2: Double, r: Double) -> Double {
    let term = pow(sin((lat2 - lat1) / 2.0), 2) + cos(lat1) * pow(sin((lon2 - lon1) / 2), 2)
    return 2 * r * asin(sqrt(term))
}
