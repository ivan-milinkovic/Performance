import Foundation

struct Profiler {
    
    static private var values = [Int64](repeating: 0, count: 16)
    
    static func reset() {
        let _ = t_start // static variables are initialized lazily when first used, so manually force it to initialize early
        for i in 0..<values.count {
            values[i] = 0
        }
    }
    
    static func start(_ i: Int) {
        let t = mach_absolute_time()
        values[i] = values[i] + Int64(t - t_start)
    }
    
    static func end(_ i: Int) {
        let dt = Int64(mach_absolute_time() - t_start)
        values[i] = values[i] - dt
    }
    
    static func ticks(_ i: Int) -> Int64 {
        abs(values[i])
    }
    
    static func nanos(_ i: Int) -> Double {
        let nanos = abs((values[i] * Int64(timeInfo.numer)) / Int64(timeInfo.denom))
        return Double(nanos)
    }
    
    static func seconds(_ i: Int) -> Double {
        nanos(i) / 1_000_000_000
    }
    
    static private let t_start: UInt64 = mach_absolute_time()
    
    static private var timeInfo: mach_timebase_info = {
        var ti = mach_timebase_info()
        let status = mach_timebase_info(&ti)
        precondition(status == KERN_SUCCESS)
        return ti
    }()
    
}
