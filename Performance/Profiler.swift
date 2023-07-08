import Foundation

struct Profiler {
    
    static private var values = [UInt64](repeating: 0, count: 10)
    
    static func start(_ i: Int) {
        values[i] += mach_absolute_time()
    }
    
    static func end(_ i: Int) {
        values[i] = mach_absolute_time() - values[i]
    }
    
    static func nanos(_ i: Int) -> Double {
        let nanos = (values[i] * UInt64(timeInfo.numer)) / UInt64(timeInfo.denom)
        return Double(nanos)
    }
    
    static func seconds(_ i: Int) -> Double {
        nanos(i) / 1_000_000_000
    }
    
    static private var timeInfo: mach_timebase_info = {
        var ti = mach_timebase_info()
        let status = mach_timebase_info(&ti)
        precondition(status == KERN_SUCCESS)
        return ti
    }()
    
}
