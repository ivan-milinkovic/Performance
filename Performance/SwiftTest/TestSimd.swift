import Foundation
import Accelerate

func testSimd() {
    var v1 : [Float] = [1,2,3,4,5,6,7,8]
    var v2 : [Float] = [1,2,3,4,5,6,7,8]
    let N = 1000 // makes a big difference
    
//    warmUpCache(&v1, &v2)
    // order can matter
    testDotVDsp(N, &v1, &v2)
    testDotBlas(N, &v1, &v2)
    testDotFor(N, &v1, &v2)
}

func testDotFor(_ N: Int, _ v1 : inout [Float], _ v2 : inout [Float]) {
    let t0 = Date()
    var tsum : Float = 0.0
    var n = 0; while n < N { defer { n+=1 }
        var sum = Float(0)
        let cnt = v1.count
        var i = 0; while i < cnt  { defer { i+=1 }
            sum += v1[i] * v2[i]
        }
        tsum += sum
    }
    let t1 = Date().timeIntervalSince(t0) * 1000
    print("\nfor:\n", tsum/Float(N), "\n", t1, "ms")
}

func testDotBlas(_ N: Int, _ v1 : inout [Float], _ v2 : inout [Float]) {
    let t0 = Date()
    var sum : Float = 0.0
    var n = 0; while n < N { defer { n+=1 }
        sum += cblas_sdot(Int32(v1.count), &v1, 1, &v2, 1)
    }
    let t1 = Date().timeIntervalSince(t0) * 1000
    print("\nblas:\n", sum/Float(N), "\n", t1, "ms")
}

func testDotVDsp(_ N: Int, _ v1 : inout [Float], _ v2 : inout [Float]) {
    let t0 = Date()
    var tsum : Float = 0.0
    var n = 0; while n < N { defer { n+=1 }
        let cnt = vDSP_Length(v1.count)
        var sum = Float(0.0)
        vDSP_dotpr(&v1, 1, &v2, 1, &sum, cnt)
        tsum += sum
    }
    let t1 = Date().timeIntervalSince(t0) * 1000
    print("\nvdsp:\n", tsum/Float(N), "\n", t1, "ms")
}

func warmUpCache(_ v1 : inout [Float], _ v2 : inout [Float]) {
    let cnt = v1.count
    var tmp : Float = 0.0
    var i = 0; while i < cnt  { defer { i+=1 }
        tmp += v1[i] + v2[i]
    }
}
