import Foundation

func testCleanCode() {
    let cnt = 1_000_000
    
    let classShapes = genClassShapes(cnt: cnt)
    let structShapes = genClassShapes(cnt: cnt)
    let staticShapes = genStaticShapes(cnt: cnt)
    
    let epochs = 1
    let t_vt_class = measureVT(shapes: classShapes, epochs: epochs)
    let t_vt_struct = measureVT(shapes: structShapes, epochs: epochs)
    let t_static = measureStatic(shapes: staticShapes, epochs: epochs)
    
    print("class:", t_vt_class.string)
    print("struct:", t_vt_struct.string)
    print("static:", t_static.string)
}


// measurements

private func measureVT(shapes: [IShape], epochs: Int) -> Duration {
    var dt = 0.0
    let cnt = shapes.count
    var e = 0; while e < epochs {
        let t0 = Date()
        var i = 0; while i < cnt {
            _ = shapes[i].area()
            i += 1
        }
        dt += Date().timeIntervalSince(t0)
        e += 1
    }
    return Duration.seconds(dt)
}



private func measureStatic(shapes: [Shape], epochs: Int) -> Duration {
    var dt = 0.0
    let cnt = shapes.count
    var e = 0; while e < epochs {
        let t0 = Date()
        var i = 0; while i < cnt {
            _ = shapes[i].area()
            i += 1
        }
        dt += Date().timeIntervalSince(t0)
        e += 1
    }
    return Duration.seconds(dt)
}


// data generation


private func genStaticShapes(cnt: Int) -> [Shape] {
    var a = [Shape]()
    a.reserveCapacity(cnt)
    for _ in 0..<cnt/4 {
        a.append(Shape(type: .square, w: randVal(), h: randVal()))
        a.append(Shape(type: .rectangle, w: randVal(), h: randVal()))
        a.append(Shape(type: .triangle, w: randVal(), h: randVal()))
        a.append(Shape(type: .circle, w: randVal(), h: randVal()))
    }
    return a
}

private func genClassShapes(cnt: Int) -> [IShape] {
    var a = [IShape]()
    a.reserveCapacity(cnt)
    for _ in 0..<cnt/4 {
        a.append(CSquare(w: randVal()))
        a.append(CRectangle(w: randVal(), h: randVal()))
        a.append(CTriangle(w: randVal(), h: randVal()))
        a.append(CCircle(w: randVal()))
    }
    return a
}

private func genStructShapes(cnt: Int) -> [IShape] {
    var a = [IShape]()
    a.reserveCapacity(cnt)
    for _ in 0..<cnt/4 {
        a.append(SSquare(w: randVal()))
        a.append(SRectangle(w: randVal(), h: randVal()))
        a.append(STriangle(w: randVal(), h: randVal()))
        a.append(SCircle(w: randVal()))
    }
    return a
}

private func randVal() -> Double {
    Double.random(in: 1...10)
}


//
// static
//

enum ShapeType {
    case square, rectangle, triangle, circle
}

struct Shape {
    let type: ShapeType
    let w: Double
    let h: Double
    
    func area() -> Double {
        switch type {
        case .square:
            return w * w
        case .rectangle:
            return w * h
        case .triangle:
            return 0.5 * w * h
        case .circle:
            return Double.pi * w * w
        }
    }
}




//
// Polymorphism
//


private protocol IShape {
    func area() -> Double
}


// Class versions

private class CSquare : IShape {
    let w : Double
    init(w: Double) {
        self.w = w
    }
    func area() -> Double {
        w * w
    }
}

private class CRectangle : IShape {
    let w : Double
    let h : Double
    init(w: Double, h: Double) {
        self.w = w
        self.h = h
    }
    func area() -> Double {
        w * h
    }
}

private class CTriangle : IShape {
    let w : Double
    let h : Double
    init(w: Double, h: Double) {
        self.w = w
        self.h = h
    }
    func area() -> Double {
        0.5 * w * h
    }
}

private class CCircle : IShape {
    let w : Double
    init(w: Double) {
        self.w = w
    }
    func area() -> Double {
        Double.pi * w * w
    }
}




// Struct versions


private struct SSquare : IShape {
    let w : Double
    func area() -> Double {
        w * w
    }
}

private struct SRectangle : IShape {
    let w : Double
    let h : Double
    func area() -> Double {
        w * h
    }
}

private struct STriangle : IShape {
    let w : Double
    let h : Double
    func area() -> Double {
        0.5 * w * h
    }
}

private struct SCircle : IShape {
    let w : Double
    func area() -> Double {
        Double.pi * w * w
    }
}
