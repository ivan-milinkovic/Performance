import Foundation

//private let inputFile = "listing37"
//private let inputFile = "listing38"
private let inputFile = "listing39"
//private let inputFile = "listing40"

func testcpu() {
    let data = loadFile()
    print(data.binStr)
    
    let cmds = parse(data: data)
    cmds.forEach { print($0) }
    
    let asm = makeSource(cmds: cmds)
    print(asm)
    
//    writeFile(asm)
}

private func loadFile() -> Data {
    let inputFileUrl = dataDirUrl.appending(path: inputFile, directoryHint: URL.DirectoryHint.notDirectory)
    let data = try! Data(contentsOf: inputFileUrl)
    return data
}

private func writeFile(_ asm: String) {
    let outputFileUrl = dataDirUrl.appending(path: inputFile + "g.asm", directoryHint: URL.DirectoryHint.notDirectory)
    try! asm.write(to: outputFileUrl, atomically: false, encoding: .ascii)
}

private func parse(data: Data) -> [Command] {
    var cmds = [Command]()
    var i = data.makeIterator()
    while true {
        guard let b = i.next() else { break }
        
        // check the short mov
        var opcode = (b & 0b1111_0000) >> 4
        if opcode == Opcode.movImmediate.rawValue {
            let W = ((b & 0b0000_1000) >> 3) != 0
            let reg = b & 0b0000_0111
            let register = resolveReg(W: W, reg: reg)
            let (dataLow, dataHigh) = readDataFields(wide: W, dataIterator: &i)
            cmds.append(.moveImmediate(w: W, reg: register, d0: dataLow, d1: dataHigh))
            continue
        }
        
        opcode = (b & 0b1111_1100) >> 2
        if opcode == Opcode.movRegMem.rawValue {
            let D = ((b & 0b0000_0010) >> 1) != 0
            let W = (b & 0b0000_0001) != 0
            
            guard let b2 = i.next() else { fatalError("unexpected binary") }
            let mod = (b2 & 0b1100_0000) >> 6
            let reg = (b2 & 0b0011_1000) >> 3
            let rm = (b2 & 0b0000_0111)
            
            let modEnum = Mod(rawValue: mod)!
            let regEnum = resolveReg(W: W, reg: reg)
            let rmEnum = resolveRM(mod: modEnum, W: W, rm: rm)
            
            var dispLow : UInt8 = 0
            var dispHigh : UInt8 = 0
            if modEnum == .mem_8 || modEnum == .mem_16 {
                (dispLow, dispHigh) = readDataFields(wide: (modEnum == .mem_16), dataIterator: &i)
            }
            cmds.append(.moveRegMem(d: D, w: W, mod: modEnum, reg: regEnum, rm: rmEnum, d0: dispLow, d1: dispHigh))
            continue
        }
        
    }
    return cmds
}

private func resolveReg(W: Bool, reg: UInt8) -> Reg {
    let r : Reg
    switch reg {
    case 0b000: r = !W ? .AL : .AX
    case 0b001: r = !W ? .CL : .CX
    case 0b010: r = !W ? .DL : .DX
    case 0b011: r = !W ? .BL : .BX
    case 0b100: r = !W ? .AH : .SP
    case 0b101: r = !W ? .CH : .BP
    case 0b110: r = !W ? .DH : .SI
    case 0b111: r = !W ? .BH : .DI
    default: fatalError("Unexpected reg: \(reg)")
    }
    return r
}

private func resolveRM(mod: Mod, W: Bool, rm: UInt8) -> RM {
    
    // reg to reg
    if mod == .reg_0 {
        return RM.reg(bits: rm, reg: resolveReg(W: W, reg: rm))
    }
    
    // Base pattern for EAC (Effective Address Calculation)
    var regs = rmEacMap[Int(rm)]
    if rm == 0b110 && (mod == .mem_8 || mod == .mem_16) {
        regs = [Reg.BP]
    }
    return RM.eac(bits: rm, regs: regs, disp: mod.rawValue)
}

private func readDataFields(wide: Bool, dataIterator i: inout Data.Iterator) -> (dataLow: UInt8, dataHigh: UInt8) {
    guard let dataLow = i.next() else { fatalError("unexpected eof") }
    var dataHigh : UInt8 = 0
    if wide {
        guard let dataHighByte = i.next() else { fatalError("unexpected eof") }
        dataHigh = dataHighByte
    }
    return (dataLow, dataHigh)
}

enum Command {
    case moveRegMem(d: Bool, w: Bool, mod: Mod, reg: Reg, rm: RM, d0: UInt8, d1: UInt8)
    case moveImmediate(w: Bool, reg: Reg, d0: UInt8, d1: UInt8)
}

extension Command: CustomStringConvertible {
    var opcode: Opcode {
        switch self {
        case .moveRegMem: return .movRegMem
        case .moveImmediate: return .movImmediate
        }
    }
    
    var description: String {
        switch self {
        case .moveRegMem(let d, let w, let mod, let reg, let rm, let d0, let d1):
            return "d: \(d) \t w: \(w), \t mod: \(mod), \t reg: \(reg), \t rm: \(rm), \t d0: \(d0.binStr), \t d1: \(d1.binStr)"
            
        case .moveImmediate(let w, let reg, let d0, let d1):
            return "w: \(w) \t reg: \(reg) \t d0: \(d0.binStr) \t d1: \(d1.binStr)"
        }
    }
}

enum RM {
    case reg(bits: UInt8, reg: Reg)
    case eac(bits: UInt8, regs: [Reg], disp: UInt8)
}

extension RM: CustomStringConvertible {
    var description: String {
        switch self {
        case .reg(let bits, let reg):
            return "{ \( binstr(bits, padding: 3) ), \(reg) }"
        case .eac(let bits, let regs, let disp):
            let regsStr = regs.map { "\($0)" }
            var padding = ""
            if regs.count == 1 { padding = "\t\t" }
            else if regs.count == 0 { padding = "\t\t\t" }
            return "{ \( binstr(bits, padding: 3) ), \(regsStr)\(padding) + \(disp * 8) }"
        }
    }
}

let rmEacMap : [[Reg]] = [
    [.BX, .SI],
    [.BX, .DI],
    [.BP, .SI],
    [.BP, .DI],
    [.SI],
    [.DI],
    [],
    [.BX]
]

enum Reg {
    case AL, AH, AX
    case BL, BH, BX
    case CL, CH, CX
    case DL, DH, DX
    case SP, BP, SI, DI
}

enum Opcode: UInt8 {
    case movRegMem = 0b100010
    case movImmediate = 0b1011
}

enum Mod: UInt8 {
    case mem_0 = 0
    case mem_8
    case mem_16
    case reg_0
}

private func makeSource(cmds: [Command]) -> String {
    var str = "bits 16\n\n"
    for c in cmds {
        str.append(asmString(c.opcode))
        str.append(" ")

        switch c {
        case .moveRegMem(let d, let w, let mod, let reg, let rm, let d0, let d1):
            let regStr = asmString(reg)
            var rmStr : String
            switch rm {
            case .reg(_, let reg):
                rmStr = asmString(reg)
            case .eac(_, let regs, let disp):
                rmStr = "["
                rmStr += regs.map(asmString(_:)).joined(separator: " + ")
                if disp > 0 {
                    let offset : UInt16 = (UInt16(d1) << 8) | UInt16(d0)
                    rmStr += " + \(offset)"
                }
                rmStr += "]"
            }
            
            str.append(regStr + ", ")
            str.append(rmStr)
            
        case .moveImmediate(let w, let reg, let d0, let d1):
            break
        }
        
        if c.opcode == .movRegMem {
            
            
        }
        str.append("\n")
    }
    return str
}

private func asmString(_ c: Opcode) -> String {
    switch c {
    case .movRegMem, .movImmediate: return "mov"
    }
}

private func asmString(_ r: Reg) -> String {
    "\(r)"
}

/*
 let dst : UInt8 = (c.D == 0) ? c.RM : c.REG
 let src : UInt8 = (c.D == 0) ? c.REG : c.RM
 
 let dstStr = (c.W == 0) ? asmString(RegisterHalf(rawValue: dst)!)
 : asmString(RegisterFull(rawValue: dst)!)
 
 let srcStr = (c.W == 0) ? asmString(RegisterHalf(rawValue: src)!)
 : asmString(RegisterFull(rawValue: src)!)
 
 let first = (c.D == 0) ? srcStr : dstStr
 let second = (c.D == 0) ? dstStr : srcStr
 */

//private func asmString(_ r: RegisterHalf) -> String {
//    switch r {
//    case .AL: return "AL"
//    case .CL: return "CL"
//    case .DL: return "DL"
//    case .BL: return "BL"
//    case .AH: return "AH"
//    case .CH: return "CH"
//    case .DH: return "DH"
//    case .BH: return "BH"
//    }
//}
//
//private func asmString(_ r: RegisterFull) -> String {
//    switch r {
//    case .AX: return "AX"
//    case .CX: return "CX"
//    case .DX: return "DX"
//    case .BX: return "BX"
//    case .SP: return "SP"
//    case .BP: return "BP"
//    case .SI: return "SI"
//    case .DI: return "DI"
//    }
//}
