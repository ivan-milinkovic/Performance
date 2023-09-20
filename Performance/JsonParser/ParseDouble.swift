import Foundation

func tryMakeDouble(startIndex: Int, length: Int, data: Data) -> Double? {
    // ascii:
    // 48: 0
    // 57: 9
    // 46: .
    // 43: +
    // 45: -
    
    if length == 0 || data.isEmpty || (startIndex + length) > data.count {
        return nil
    }
    
    var hasDecimalPart = false
    
    var num: Double = 0.0
    
    // integer part
    
    let byte = data[startIndex]
    let hasMinus = (byte == 45)
    let hasPlus = (byte == 43)
    let startOffset = (hasMinus || hasPlus) ? 1 : 0
    let endIndex = startIndex + length
    
    var j = (startIndex+startOffset); while j < endIndex { defer { j += 1 }
        let byte = data[j]
        
        if byte == 46 {
            hasDecimalPart = true
            break
        }
        
        if byte < 48 || byte > 57 {
            return nil
        }
        
        let digit = byte - 48
        num = num * 10 + Double(digit)
    }
    
    if hasDecimalPart {
        
        var decimalPart: Double = 0.0
        
        var k = j; while k < endIndex { defer { k += 1 }
            let byte = data[k]
            
            if byte < 48 || byte > 57 {
                return nil
            }
            
            let digit = byte - 48
            let expo = pow(10.0, Double(k-j+1))
            decimalPart += Double(digit) / expo
        }
        num += decimalPart
    }
    
    if hasMinus {
        num *= -1
    }
    
    return num
}

func tryMakeDouble2(startIndex: Int, length: Int, data: Data) -> Double? {
    // ascii:
    // 48: 0
    // 57: 9
    // 46: .
    // 43: +
    // 45: -
    
    if length == 0 || data.isEmpty || (startIndex + length) > data.count {
        return nil
    }
    
    var num: Double = 0.0
    
    // integer part
    
    let byte = data[startIndex]
    let hasMinus = (byte == 45)
    let hasPlus = (byte == 43)
    let startOffset = (hasMinus || hasPlus) ? 1 : 0
    let endIndex = startIndex + length
    var decimalPointIndex = -1
    
    var j = (startIndex+startOffset); while j < endIndex { defer { j += 1 }
        let byte = data[j]
        
        if byte == 46 {
            if decimalPointIndex != -1 {
                return nil
            }
            decimalPointIndex = j
            continue
        }
        
        if byte < 48 || byte > 57 {
            return nil
        }
        
        let digit = byte - 48
        num = num * 10 + Double(digit)
    }
    
    if decimalPointIndex != -1 {
        let decimals = endIndex - decimalPointIndex - 1
        let expo = pow(10.0, Double(decimals))
        num = num / expo
    }
    
    if hasMinus {
        num *= -1
    }
    
    return num
}

func tryMakeDouble3(startIndex: Int, length: Int, bytes: UnsafeRawBufferPointer) -> Double? {
    // ascii:
    // 48: 0
    // 57: 9
    // 46: .
    // 43: +
    // 45: -
    
    if length == 0 {
        return nil
    }
    
    var hasDecimalPart = false
    
    var num: Double = 0.0
    
    // integer part
    
    let byte = bytes[startIndex]
    let hasMinus = (byte == 45)
    let hasPlus = (byte == 43)
    let startOffset = (hasMinus || hasPlus) ? 1 : 0
    let endIndex = startIndex + length
    
    var j = (startIndex+startOffset); while j < endIndex { defer { j += 1 }
        let byte = bytes[j]
        
        if byte == 46 {
            hasDecimalPart = true
            break
        }
        
        if byte < 48 || byte > 57 {
            return nil
        }
        
        let digit = byte - 48
        num = num * 10 + Double(digit)
    }
    
    if hasDecimalPart {
        
        var decimalPart: Double = 0.0
        var tens = 1.0
        
        var k = j; while k < endIndex { defer { k += 1 }
            let byte = bytes[k]
            
            if byte < 48 || byte > 57 {
                return nil
            }
            
            let digit = byte - 48
            tens *= 10
            decimalPart += Double(digit) / tens
        }
        num += decimalPart
    }
    
    if hasMinus {
        num *= -1
    }
    
    return num
}
