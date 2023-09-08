import Foundation

func add1(cnt: Int, array: [Int]) -> Int {
    var sum = 0
    var i = 0
    while i < cnt {
        sum += array[i]
        i+=1
    }
    return sum
}

func add2(cnt: Int, array: [Int]) -> Int {
    var sum1 = 0
    var sum2 = 0
    var i = 0
    while i < cnt {
        sum1 += array[i]
        sum2 += array[i+1]
        i+=2
    }
    return sum1 + sum2
}

func add4(cnt: Int, array: [Int]) -> Int {
    var sum1 = 0
    var sum2 = 0
    var sum3 = 0
    var sum4 = 0
    var i = 0
    while i < cnt {
        sum1 += array[i]
        sum2 += array[i+1]
        sum3 += array[i+2]
        sum4 += array[i+3]
        i+=4
    }
    return sum1 + sum2 + sum3 + sum4
}

func add6(cnt: Int, array: [Int]) -> Int {
    var sum1 = 0
    var sum2 = 0
    var sum3 = 0
    var sum4 = 0
    var sum5 = 0
    var sum6 = 0
    var i = 0
    while i < cnt {
        sum1 += array[i]
        sum2 += array[i+1]
        sum3 += array[i+2]
        sum4 += array[i+3]
        sum5 += array[i+4]
        sum6 += array[i+5]
        i+=6
    }
    return sum1 + sum2 + sum3 + sum4 + sum5 + sum6
}

func add8(cnt: Int, array: [Int]) -> Int {
    var sum1 = 0
    var sum2 = 0
    var sum3 = 0
    var sum4 = 0
    var sum5 = 0
    var sum6 = 0
    var sum7 = 0
    var sum8 = 0
    var i = 0
    while i < cnt {
        sum1 += array[i]
        sum2 += array[i+1]
        sum3 += array[i+2]
        sum4 += array[i+3]
        sum5 += array[i+4]
        sum6 += array[i+5]
        sum7 += array[i+6]
        sum8 += array[i+7]
        i+=8
    }
    return sum1 + sum2 + sum3 + sum4 + sum5 + sum6 + sum7 + sum8
}

func add10(cnt: Int, array: [Int]) -> Int {
    var sum1 = 0
    var sum2 = 0
    var sum3 = 0
    var sum4 = 0
    var sum5 = 0
    var sum6 = 0
    var sum7 = 0
    var sum8 = 0
    var sum9 = 0
    var sum10 = 0
    var i = 0
    while i < cnt {
        sum1 += array[i]
        sum2 += array[i+1]
        sum3 += array[i+2]
        sum4 += array[i+3]
        sum5 += array[i+4]
        sum6 += array[i+5]
        sum7 += array[i+6]
        sum8 += array[i+7]
        sum9 += array[i+8]
        sum10 += array[i+9]
        i+=10
    }
    return sum1 + sum2 + sum3 + sum4 + sum5 + sum6 + sum7 + sum8 + sum9 + sum10
}

//let count = 1024
//let count = 1008 // 48*21
//let count = 1056 // 48*22
let count = 1200 // least common multiple
let array = [Int](repeating: 1, count: count)
let epochs = 1

let desc = ["t1", "t2", "t4", "t6", "t8", "t10"]
let fn = [add1, add2, add4, add6, add8, add10]

func testAdd() {
    let clock = ContinuousClock()
    for i in 0..<fn.count {
        let f = fn[i]
        let t = clock.measure {
            var i = 0
            while i < epochs {
                _ = f(count, array)
                i += 1
            }
        }
        print("\(desc[i]):\t", t.string)
    }
    
    let t = clock.measure {
        var i = 0
        while i < count {
            i += 1
        }
    }
    print("inc:", t.string)
}

