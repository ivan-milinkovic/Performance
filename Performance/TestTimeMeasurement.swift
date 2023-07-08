import Foundation

func testTimeMeasurement() {
    //let pointer = UnsafeMutablePointer<mach_timebase_info_data_t>.allocate(capacity: 1)
    //precondition(mach_timebase_info(pointer) == KERN_SUCCESS)
    //let info = pointer.pointee
    //defer { pointer.deallocate() }

    var info = mach_timebase_info_data_t()
    precondition(mach_timebase_info(&info) == KERN_SUCCESS)

    let t_ck = ContinuousClock().measure {
        doSomeWork()
    }
    print("ContinuousClock:", t_ck)

    let d0 = Date()
    doSomeWork()
    let ti = Date().timeIntervalSince(d0)
    print("Date", ti)

    let t0 = mach_absolute_time()
    doSomeWork()
    let t1 = mach_absolute_time() - t0
    let dt = (t1 * UInt64(info.numer)) / UInt64(info.denom)
    let s = Double(dt) / 1_000_000_000
    //print(dt, "ns")
    print("mach_absolute_time:", s, "s")
    
    Profiler.start(0)
    doSomeWork()
    Profiler.end(0)
    print("Profiler:", Profiler.seconds(0), "s")
}

private func doSomeWork() {
    for _ in 0..<10 {
        let _ = Int.random(in: 0..<10)
    }
}
