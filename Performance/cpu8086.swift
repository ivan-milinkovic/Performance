import Foundation

private let inputFile =
//"listing37"
//"listing38"
//"listing39"
"listing41"
//"test"


func testcpu() {
    let data = loadFile()
    print(data.binStr)
    
    let asm = dissasemble(data)
    print("\nAsm:"); print(asm)
    
//    writeFile(asm)
}


func dissasemble(_ data: Data) -> String {
    let cmds = parse(data: data)
    let asm = makeSource(cmds: cmds)
    return asm
}


//
// parsing
//

private func parse(data: Data) -> [Command] {
    var cmds = [Command]()
    var i = DataIterator(iter: data.makeIterator())
    while true {
        guard let b = i.next() else { break }
        
        // Check short opcode
        
        var opcode = (b & 0b1111_0000) >> 4
        
        if opcode == ShortOpcode.movImmediateToRegMem.rawValue {
            let W = ((b & 0b0000_1000) >> 3) != 0
            let reg = b & 0b0000_0111
            let regEnum = resolveReg(W: W, reg: reg)
            let (data0, data1) = readDataFields(wide: W, dataIterator: &i)
            cmds.append(Command(opcode: .short(.movImmediateToRegMem),
                                dsv: false,
                                w: W,
                                mod: nil,
                                reg: regEnum,
                                rm: nil,
                                disp0: nil,
                                disp1: nil,
                                data0: data0,
                                data1: data1))
            continue
        }
        
        // Check simple opcode
        
        opcode = (b & 0b1111_1100) >> 2
        
        if let simpleOpcode = SimpleOpcode(rawValue: opcode) {
            if simpleOpcode.isRegMem {
                let D = ((b & 0b0000_0010) >> 1) != 0
                let W = (b & 0b0000_0001) != 0
                let (modEnum, reg, rmEnum, disp0, disp1) = parseStandard2ndByte(iter: &i, W: W)
                let regEnum = resolveReg(W: W, reg: reg)
                cmds.append(Command(opcode: .simple(simpleOpcode),
                                    dsv: D,
                                    w: W,
                                    mod: modEnum,
                                    reg: regEnum,
                                    rm: rmEnum,
                                    disp0: disp0,
                                    disp1: disp1,
                                    data0: nil,
                                    data1: nil))
                continue
            }
            else if simpleOpcode.isImmediateToAcc {
                let S = false
                let W = (b & 0b0000_0001) != 0
                let (data0, data1) = readDataFields(wide: W, dataIterator: &i)
                cmds.append(Command(opcode: .simple(simpleOpcode),
                                    dsv: S,
                                    w: W,
                                    mod: nil,
                                    reg: nil,
                                    rm: nil,
                                    disp0: nil,
                                    disp1: nil,
                                    data0: data0,
                                    data1: data1))
                continue
            }
        }
        
        // Check composite opcode
        
        // ADD/SUB/CMP - Immediate to reg/mem
        
        if opcode == CompositeOpcode.Part1.AddSubCmpImmediate.rawValue {
            let S = ((b & 0b0000_0010) >> 1) != 0
            let W = (b & 0b0000_0001) != 0
            let (modEnum, opcodePart2, rmEnum, disp0, disp1) = parseStandard2ndByte(iter: &i, W: W)
            
            let opcodeEnum = Opcode.composite(.AddSubCmp(CompositeOpcode.Part2(rawValue: opcodePart2)!))
            
            var (data0, data1) = readDataFields(wide: false, dataIterator: &i)
            if S {
                let data16 = Int16(data0)
                data0 = UInt8(data16 & 0x00FF)
                data1 = UInt8((data16 >> 8) & 0x00FF)
            }
            cmds.append(Command(opcode: opcodeEnum,
                                dsv: S,
                                w: W,
                                mod: modEnum,
                                reg: nil,
                                rm: rmEnum,
                                disp0: disp0,
                                disp1: disp1,
                                data0: data0,
                                data1: data1))
            continue
        }
        
        fatalError("Unhandled byte: \(opcode.binStr)")
    }
    return cmds
}


private func parseStandard2ndByte(iter i: inout DataIterator, W: Bool)
    -> (mod: Mod, regOrOpcode: UInt8, rm: RM, disp0: UInt8, disp1: UInt8?) {

    guard let b2 = i.next() else { fatalError("unexpected binary") }
    let mod = (b2 & 0b1100_0000) >> 6
    let regOrOpcodeSuffix = (b2 & 0b0011_1000) >> 3
    let rm = (b2 & 0b0000_0111)
    
    let modEnum = Mod(rawValue: mod)!
    let rmEnum = resolveRM(mod: modEnum, W: W, rm: rm)
    
    var disp0 : UInt8 = 0
    var disp1 : UInt8? = 0
    if modEnum == .mem_8 || modEnum == .mem_16 || ( modEnum == .mem_0 && rm == 0b110 ) {
        let isWide = (modEnum == .mem_16) || ( modEnum == .mem_0 && rm == 0b110 )
        (disp0, disp1) = readDataFields(wide: isWide, dataIterator: &i)
    }
    return (modEnum, regOrOpcodeSuffix, rmEnum, disp0, disp1)
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
    return RM.eac(bits: rm, regs: regs)
}

private func readDataFields(wide: Bool, dataIterator i: inout DataIterator) -> (dataLow: UInt8, dataHigh: UInt8?) {
    guard let dataLow = i.next() else { fatalError("unexpected eof") }
    var dataHigh : UInt8? = nil
    if wide {
        guard let dataHighByte = i.next() else { fatalError("unexpected eof") }
        dataHigh = dataHighByte
    }
    return (dataLow, dataHigh)
}





//
// Model
//

struct Command {
    let opcode: Opcode
    let dsv: Bool // D/S/V
    let w: Bool
    let mod: Mod?
    let reg: Reg?
    let rm: RM?
    let disp0: UInt8?
    let disp1: UInt8?
    let data0: UInt8?
    let data1: UInt8?
}

enum Opcode {
    case short(ShortOpcode)
    case simple(SimpleOpcode)
    case composite(CompositeOpcode)
}

enum ShortOpcode: UInt8 {
    case movImmediateToRegMem = 0b1011
}

enum SimpleOpcode: UInt8 {
    
    case movRegMem = 0b100010
    
    case addRegMem = 0b000000
    case addImmediateToAcc = 0b000001
    
    case subRegMem = 0b001010
    case subImmediateToAcc = 0b001011
    
    case cmpRegMem = 0b001110
    case cmpImmediateToAcc = 0b001111
}

enum CompositeOpcode {
    
    case AddSubCmp(Part2)
    
    enum Part1: UInt8 {
        case AddSubCmpImmediate = 0b100000
    }
    
    enum Part2: UInt8 {
        case add = 0
        case sub = 0b101
        case cmp = 0b111
    }
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
    case eac(bits: UInt8, regs: [Reg])
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
        
        // Check R/M first as reg might not exist
        if let rm = c.rm {
            let rmStr = asmRm(rm: rm, disp0: c.disp0, disp1: c.disp1)
            
            let first: String
            let second: String
            
            if let reg = c.reg {    // register <-> memory
                let regStr = asmString(reg)
                first = c.dsv ? regStr : rmStr
                second = !c.dsv ? regStr : rmStr
            }
            else {  // immediate to register/memory - constant
                first = rmStr
                second = asmData(data0: c.data0!, data1: c.data1)
            }
            
            str.append(first + ", " + second)
        }
        
        else if let reg = c.reg { // immediate to register only - constant
            let regStr = asmString(reg)
            let dataStr = asmData(data0: c.data0!, data1: c.data1)
            str.append(regStr + ", " + dataStr)
        }
        
        else {
            let reg: Reg = c.w ? Reg.AX : Reg.AL
            let regStr = asmString(reg)
            let dataStr = asmData(data0: c.data0!, data1: c.data1)
            str.append(regStr + ", " + dataStr)
        }
        
        str += "\n"
    }
    
    return str
}

private func asmRm(rm: RM, disp0: UInt8?, disp1: UInt8?) -> String {
    var str : String
    switch rm {
    case .reg(_, let reg):
        str = asmString(reg)
        
    case .eac(_, let regs):
        str = "["
        str += regs.map(asmString(_:)).joined(separator: " + ")
        
        if let disp0 = disp0 {
            let dispStr = asmData(data0: disp0, data1: disp1)
            if dispStr != "0" {
                str += " + " + dispStr
            }
        }
        str += "]"
    }
    return str
}

private func asmData(data0: UInt8, data1: UInt8?) -> String {
    var data : UInt16 = UInt16(data0)
    if let data1 = data1 {
        data = (UInt16(data1) << 8) | data
    }
    return "\(data)"
}

private func asmString(_ opcode: Opcode) -> String {
    switch opcode {
    case .short(let shortOpcode):
        switch shortOpcode {
        case .movImmediateToRegMem: return "MOV"
        }
    case .simple(let simpleOpcode):
        switch simpleOpcode {
        case .movRegMem: return "MOV"
        case .addRegMem, .addImmediateToAcc: return "ADD"
        case .subRegMem, .subImmediateToAcc: return "SUB"
        case .cmpRegMem, .cmpImmediateToAcc: return "CMP"
        }
    case .composite(let compositeOpcode):
        switch compositeOpcode {
        case .AddSubCmp(let suffix):
            switch suffix {
            case .add: return "ADD"
            case .sub: return "SUB"
            case .cmp: return "CMP"
            }
        }
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

extension Command {
    
    var isWideDisp: Bool {
        disp0 != nil && disp0 != nil
    }
    
    var isWideData: Bool {
        data0 != nil && data1 != nil
    }
}

extension SimpleOpcode {
    
    var isRegMem: Bool {
        switch self {
        case .movRegMem, .addRegMem, .subRegMem, .cmpRegMem:
            return true
        case .addImmediateToAcc, .subImmediateToAcc, .cmpImmediateToAcc:
            return false
        }
    }
    
    var isImmediateToAcc: Bool {
        switch self {
        case .movRegMem, .addRegMem, .subRegMem, .cmpRegMem:
            return false
        case .addImmediateToAcc, .subImmediateToAcc, .cmpImmediateToAcc:
            return true
        }
    }
}


//
// Printing
//

extension Command: CustomStringConvertible {
    var description: String {
        var str = ""
        str += asmString(self.opcode) + ": "
        str += "d/s/v: \(dsv) \t w: \(w) \t mod: \(mod.str) \t \(reg.str) \t rm: \(rm.str) \t "
        str += "disp0: \(disp0.str) \t disp1: \(disp1.str) \t data0: \(data0.str) \t data1: \(data1.str)"
        return str
    }
}

extension Optional {
    var str: String {
        switch self {
        case .some(let wrapped): return "\(wrapped)"
        case .none: return "--"
        }
    }
}


extension Optional where Wrapped: BinaryInteger {
    var str: String {
        switch self {
        case .some(let wrapped): return "\(binstr(wrapped))"
        case .none: return "--"
        }
    }
}

extension RM: CustomStringConvertible {
    var description: String {
        switch self {
        case .reg(let bits, let reg):
            return "{ \( binstr(bits, padding: 3) ), \(reg) }"
        case .eac(let bits, let regs):
            let regsStr = regs.map { "\($0)" }
            var padding = ""
            if regs.count == 1 { padding = "\t\t" }
            else if regs.count == 0 { padding = "\t\t\t" }
            return "{ \( binstr(bits, padding: 3) ), \(regsStr)\(padding) }"
        }
    }
}
