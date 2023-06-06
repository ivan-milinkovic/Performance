import Foundation

/*
 nasm listing90.asm
 (will generate listing39g)
 cmp listing39 listing39g
 */

private let inputFile =
//                        "listing37"
//                        "listing38"
//                        "listing39"
                        "listing41"

func testcpu() {
    let data = loadFile()
    print(data.binStr)
    
    let cmds = parse(data: data)
    cmds.forEach { print($0) }
    
    let asm = makeSource(cmds: cmds)
    print("\nAsm:"); print(asm)
    
//    writeFile(asm)
}



//
// parsing
//

private func parse(data: Data) -> [Command] {
    var cmds = [Command]()
    var i = DataIterator(iter: data.makeIterator())
    while true {
        guard let b = i.next() else { break }
        
        // check the short mov
        var opcode = (b & 0b1111_0000) >> 4
        if opcode == Opcode.movImmediateToReg.rawValue {
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
            let (modEnum, regEnum, rmEnum, d0, d1) = parseStandard2ndByte(iter: &i, W: W)
            cmds.append(.moveRegMem(RegMemParams(D, W, modEnum, regEnum, rmEnum, d0, d1)))
            continue
        }
        
        if opcode == Opcode.addRegMem.rawValue {
            let D = ((b & 0b0000_0010) >> 1) != 0
            let W = (b & 0b0000_0001) != 0
            let (modEnum, regEnum, rmEnum, d0, d1) = parseStandard2ndByte(iter: &i, W: W)
            cmds.append(.addRegMem(RegMemParams(D, W, modEnum, regEnum, rmEnum, d0, d1)))
            continue
        }
        
        print("Unhandled opcode:", opcode.binStr)
    }
    return cmds
}



private func parseStandard2ndByte(iter i: inout DataIterator, W: Bool) -> (mod: Mod, reg: Reg, rm: RM, d0: UInt8, d1: UInt8) {
    guard let b2 = i.next() else { fatalError("unexpected binary") }
    let mod = (b2 & 0b1100_0000) >> 6
    let reg = (b2 & 0b0011_1000) >> 3
    let rm = (b2 & 0b0000_0111)
    
    let modEnum = Mod(rawValue: mod)!
    let regEnum = resolveReg(W: W, reg: reg)
    let rmEnum = resolveRM(mod: modEnum, W: W, rm: rm)
    
    var d0 : UInt8 = 0
    var d1 : UInt8 = 0
    if modEnum == .mem_8 || modEnum == .mem_16 {
        (d0, d1) = readDataFields(wide: (modEnum == .mem_16), dataIterator: &i)
    }
    return (modEnum, regEnum, rmEnum, d0, d1)
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

private func readDataFields(wide: Bool, dataIterator i: inout DataIterator) -> (dataLow: UInt8, dataHigh: UInt8) {
    guard let dataLow = i.next() else { fatalError("unexpected eof") }
    var dataHigh : UInt8 = 0
    if wide {
        guard let dataHighByte = i.next() else { fatalError("unexpected eof") }
        dataHigh = dataHighByte
    }
    return (dataLow, dataHigh)
}





//
// Model
//


enum Command {
    case moveRegMem(RegMemParams)
    case moveImmediate(w: Bool, reg: Reg, d0: UInt8, d1: UInt8)
    case addRegMem(RegMemParams)
}

enum Opcode: UInt8 {
    case movRegMem = 0b100010
    case movImmediateToReg = 0b1011
    
    case addRegMem = 0b000000
//    case addImmediateToReg = 0b100000
}

struct RegMemParams {
    let d: Bool
    let w: Bool
    let mod: Mod
    let reg: Reg
    let rm: RM
    let d0: UInt8
    let d1: UInt8
}

enum Mod: UInt8 {
    case mem_0 = 0
    case mem_8
    case mem_16
    case reg_0
}

enum Reg {
    case AL, AH, AX
    case BL, BH, BX
    case CL, CH, CX
    case DL, DH, DX
    case SP, BP, SI, DI
}

enum RM {
    case reg(bits: UInt8, reg: Reg)
    case eac(bits: UInt8, regs: [Reg], disp: UInt8)
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




//
// Making Source ASM
//


private func makeSource(cmds: [Command]) -> String {
    var str = "bits 16\n\n"
    for c in cmds {
        str.append(asmString(c.opcode))
        str.append(" ")

        switch c {
        case .moveRegMem(let params):
            let pstr = asmString(params)
            str.append(pstr)
            
        case .moveImmediate(let w, let reg, let d0, let d1):
            let regStr = asmString(reg)
            var offset = UInt16(d0)
            if w {
                offset |= (UInt16(d1) << 8)
            }
            let offsetStr = "\(offset)"
            
            str.append(regStr + ", " + offsetStr)
            
        case .addRegMem(let params):
            let pstr = asmString(params)
            str.append(pstr)
        }
        
        str.append("\n")
    }
    return str
}

private func asmString(_ p: RegMemParams) -> String {
    var str = ""
    let regStr = asmString(p.reg)
    var rmStr : String
    switch p.rm {
    case .reg(_, let reg):
        rmStr = asmString(reg)
    case .eac(_, let regs, let disp):
        rmStr = "["
        rmStr += regs.map(asmString(_:)).joined(separator: " + ")
        
        if disp > 0 {
            let offset : UInt16 = (UInt16(p.d1) << 8) | UInt16(p.d0)
            if offset != 0 {
                rmStr += " + \(offset)"
            }
        }
        rmStr += "]"
    }
    
    let first = p.d ? regStr : rmStr
    let second = !p.d ? regStr : rmStr
    
    str.append(first + ", " + second)
    return str
}

private func asmString(_ c: Opcode) -> String {
    switch c {
    case .movRegMem, .movImmediateToReg: return "MOV"
    case .addRegMem: return "ADD"
    }
}

private func asmString(_ r: Reg) -> String {
    "\(r)"
}




//
// Util
//

private func loadFile() -> Data {
    let inputFileUrl = dataDirUrl.appending(path: inputFile, directoryHint: URL.DirectoryHint.notDirectory)
    let data = try! Data(contentsOf: inputFileUrl)
    return data
}

private func writeFile(_ asm: String) {
    let outputFileUrl = dataDirUrl.appending(path: inputFile + "g.asm", directoryHint: URL.DirectoryHint.notDirectory)
    try! asm.write(to: outputFileUrl, atomically: false, encoding: .ascii)
}

extension Command {
    var opcode: Opcode {
        switch self {
        case .moveRegMem: return .movRegMem
        case .moveImmediate: return .movImmediateToReg
        case .addRegMem: return .addRegMem
        }
    }
}

struct DataIterator: IteratorProtocol {
    private var iter: Data.Iterator
    private(set) var i = 0
    init(iter: Data.Iterator) {
        self.iter = iter
    }
    mutating func next() -> UInt8? {
        i += 1
        return iter.next()
    }
}

extension RegMemParams {
    init(_ d: Bool, _ w: Bool, _ mod: Mod, _ reg: Reg, _ rm: RM, _ dsp0: UInt8, _ dsp1: UInt8) {
        self.d = d
        self.w = w
        self.mod = mod
        self.reg = reg
        self.rm = rm
        self.d0 = dsp0
        self.d1 = dsp1
    }
}





//
// Printing
//

extension Command: CustomStringConvertible {

    var description: String {
        switch self {
        case .moveRegMem(let params):
            return params.description
            
        case .moveImmediate(let w, let reg, let d0, let d1):
            return "w: \(w) \t reg: \(reg) \t d0: \(d0.binStr) \t d1: \(d1.binStr)"
            
        case .addRegMem(let params):
            return params.description
        }
    }
}

extension RegMemParams: CustomStringConvertible {
    var description: String {
        return "d: \(d) \t w: \(w) \t mod: \(mod) \t reg: \(reg) \t rm: \(rm) \t d0: \(d0.binStr) \t d1: \(d1.binStr)"
    }
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
