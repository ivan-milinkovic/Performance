import Foundation

// https://edge.edx.org/c4x/BITSPilani/EEE231/asset/8086_family_Users_Manual_1_.pdf
// https://github.com/cmuratori/computer_enhance/tree/main/perfaware/part1
// https://yassinebridi.github.io/asm-docs/8086_instruction_set.html

private let inputFile =
//"listing_0043_immediate_movs"
//"listing_0044_register_movs"
//"listing_0046_add_sub_cmp"
//"listing_0048_ip_register"
//"listing_0049_conditional_jumps"
//"listing_0051_memory_mov"
"listing_0052_memory_add_loop"
//"test"


func testcpu() {
//    testDissasembly()
    testRunning()
}

private func testDissasembly() {
    let data = loadFile(inputFile)
    print(data.binStr)
    
    let cmds = parse(data: data)
    let asm = makeSource(cmds: cmds)
    print("\nAsm:"); print(asm)
//    writeFile(asm)
}

private func testRunning() {
    let data = loadFile(inputFile)
    runBinary(data)
}

func runBinary(_ data: Data) {
    registers.IP = 0
    var dataIterator = DataIterator(data: data)
    while dataIterator.hasMore {
        let cmd = parse(dataIterator: &dataIterator)
        print(makeSource(cmd: cmd))
        runCommand(cmd, dataIter: &dataIterator)
    }
    print(registers)
}


func dissasemble(_ data: Data) -> String {
    registers.IP = 0
    let cmds = parse(data: data)
    let asm = makeSource(cmds: cmds)
    return asm
}


//
// Running
//

var registers = Registers()
//var ram = [UInt16].init(repeating: 0, count: 1024 * 1024 / 2) // UInt16 / 2 = 1 byte; 1024 * 1024 bytes = 1 MB
var ram = [UInt8].init(repeating: 0, count: 65536) // 2 ^ 16 = 65536

struct Registers {
    var A: UInt16 = 0
    var B: UInt16 = 0
    var C: UInt16 = 0
    var D: UInt16 = 0
    var SP: UInt16 = 0
    var BP: UInt16 = 0
    var SI: UInt16 = 0
    var DI: UInt16 = 0
    var IP : Int = 0
    var flags = Flags()
}

struct Flags {
    var Z = false // zero, 1 if result == 0
    var S = false // sign, 1 if result < 0, MSB = 1
    // not calculated currently
    var O = false // overflow
    var C = false // carry
    var P = false // parity
}

func runCommand(_ cmd: Command, dataIter: inout DataIterator) {
    let args = makeCommandArgs(cmd)
    let optype = operationType(forOpcode: cmd.opcode)
    
    switch optype {
    case .mov:
        let srcVal: UInt16
        if let src = args.src {
            srcVal = src.read(registers)
        } else {
            srcVal = args.data!
        }
        args.dest!.write(value: srcVal, registers: &registers)
        
    case .add, .sub, .cmp:
        var value: UInt16 = 0
        if let src = args.src {
            value = src.read(registers)
        } else {
            value = args.data!
        }
        let dstVal = args.dest!.read(registers)
        var sign : Int16 = 1
        if optype == .sub || optype == .cmp { sign = -1 }
        let result = UInt16(bitPattern: Int16(truncatingIfNeeded: dstVal) + sign * Int16(bitPattern: value))
        
        if optype == .add || optype == .sub {
            args.dest!.write(value: result, registers: &registers)
        }
        
        registers.flags.Z = result == 0
        registers.flags.S = (result & 0b1000_000) != 0
        
    case .jmp:
        guard case let Opcode.long(longOpcode) = cmd.opcode else { fatalError() }
        jump(longOpcode: longOpcode, disp: cmd.disp0!, dataIter: &dataIter)
    }
}

private func jump(longOpcode: LongOpcode, disp: UInt8, dataIter: inout DataIterator) {
    let disp = Int(Int8(truncatingIfNeeded: disp))
    if checkCondition(longOpcode: longOpcode) {
        dataIter.index += disp
    }
}

// https://stackoverflow.com/a/53452319/3729266
/*
 Mnemonic        Condition tested  Description
 jo              OF = 1            overflow
 jno             OF = 0            not overflow
 jc, jb, jnae    CF = 1            carry / below / not above nor equal
 jnc, jae, jnb   CF = 0            not carry / above or equal / not below
 je, jz          ZF = 1            equal / zero
 jne, jnz        ZF = 0            not equal / not zero
 jbe, jna        CF or ZF = 1      below or equal / not above
 ja, jnbe        CF or ZF = 0      above / not below or equal
 js              SF = 1            sign
 jns             SF = 0            not sign
 jp, jpe         PF = 1            parity / parity even
 jnp, jpo        PF = 0            not parity / parity odd
 jl, jnge        SF xor OF = 1     less / not greater nor equal
 jge, jnl        SF xor OF = 0     greater or equal / not less
 jle, jng    (SF xor OF) or ZF = 1 less or equal / not greater
 jg, jnle    (SF xor OF) or ZF = 0 greater / not less nor equal
 */
private func checkCondition(longOpcode: LongOpcode) -> Bool {
    switch longOpcode {
    case .JE : return registers.flags.Z
    case .JL : return registers.flags.S != registers.flags.O // xor
    case .JLE: return (registers.flags.S != registers.flags.O) || registers.flags.Z
    case .JB : return registers.flags.C
    case .JBE: return registers.flags.C || registers.flags.Z
    case .JP : return registers.flags.P
    case .JO : return registers.flags.O
    case .JS : return registers.flags.S
    case .JNE: return !registers.flags.Z
    case .JNL: return registers.flags.S != registers.flags.O
    case .JG : return (registers.flags.S != registers.flags.O) || !registers.flags.Z
    case .JNB: return !registers.flags.C
    case .JA : return registers.flags.C || registers.flags.Z
    case .JNP: return !registers.flags.P
    case .JNO: return !registers.flags.O
    case .JNS: return !registers.flags.S
    
    case .LOOP: return registers.C != 0 // manual: "run CX times"?
    case .LOOPZ: return registers.flags.Z
    case .LOOPNZ: return !registers.flags.Z
    case .JCXZ: return registers.C == 0
    }
}


private func makeCommandArgs(_ c: Command) -> CommandArgs {
    
    var regLoc: Location? = nil
    var rmLoc: Location? = nil
    var data : UInt16? = nil
    
    if let reg = c.reg {
        let regLocation = regLocation(forReg: reg)
        let regAccess = regAccess(forReg: reg)
        regLoc = Location.reg(regLoc: regLocation, regAccess: regAccess)
    }
    
    if let rm = c.rm {
        switch rm {
        case let .reg(_, reg):
            let regLoc = regLocation(forReg: reg)
            let regAccess = regAccess(forReg: reg)
            rmLoc = Location.reg(regLoc: regLoc, regAccess: regAccess)
            
        case let .eac(_, regs):
            var ptr : UInt16 = 0
            for reg in regs {
                let regLoc = regLocation(forReg: reg)
                let regVal = registers[keyPath: regLoc] // These registers are full access, like BP
                ptr += regVal
            }
            var disp = UInt16(c.disp0!)
            if let disp1 = c.disp1 {
                disp = (UInt16(disp1) << 8) | disp
            }
            ptr += disp
            rmLoc = Location.mem(index: Int(ptr), W: c.w)
        }
    }
    
    if let data0 = c.data0 {
        if let data1 = c.data1 {
            data = (UInt16(truncatingIfNeeded: data1) << 8) | UInt16(truncatingIfNeeded: data0)
        } else {
            data = (c.s ?? false) ? UInt16(data0) : UInt16(truncatingIfNeeded: data0)
        }
    }
    
    var src : Location? = nil
    var dst : Location? = nil
    
    if let D = c.d {
        dst = D ? regLoc : rmLoc
        src = !D ? regLoc : rmLoc
    } else {
        dst = regLoc ?? rmLoc
    }
    
    return CommandArgs(src: src, dest: dst, data: data)
}

private func regLocation(forReg reg: Reg) -> WritableKeyPath<Registers, UInt16> {
    switch reg {
    case .AL, .AH, .AX: return ( \Registers.A )
    case .BL, .BH, .BX: return ( \Registers.B )
    case .CL, .CH, .CX: return ( \Registers.C )
    case .DL, .DH, .DX: return ( \Registers.D )
    case .SP: return ( \Registers.SP )
    case .BP: return ( \Registers.BP )
    case .SI: return ( \Registers.SI )
    case .DI: return ( \Registers.DI )
    }
}

private func regAccess(forReg reg: Reg) -> RegAccess {
    switch reg {
    case .AL, .BL, .CL, .DL: return RegAccess.low
    case .AH, .BH, .CH, .DH: return RegAccess.high
    case .AX, .BX, .CX, .DX, .SP, .BP, .SI, .DI: return RegAccess.full
    }
}

enum OperationType {
    case mov
    case add
    case sub
    case cmp
    case jmp
}

struct CommandArgs {
    let src: Location?
    let dest: Location?
    let data: UInt16?
}

enum Location {
    case reg(regLoc: WritableKeyPath<Registers, UInt16>, regAccess: RegAccess)
    case mem(index: Int, W: Bool)
    
    func read(_ registers: Registers) -> UInt16 {
        switch self {
        case .reg(let regLoc, let regAccess):
            let regVal = registers[keyPath: regLoc]
            return regAccess.read(regVal)
            
        case .mem(let index, let W):
//            var memValue = ram[index]
//            memValue = W ? memValue : (memValue & 0xFF00)
            var memValue = UInt16(ram[index])
            if W {
                memValue = (memValue << 8) | UInt16(ram[index + 1]) // big endian
//                memValue = UInt16(ram[index + 1] << 8) | memValue
            }
            return memValue
        }
    }
    
    func write(value: UInt16, registers: inout Registers) {
        switch self {
        case let .reg(regLoc, regAccess):
            let regValue = registers[keyPath: regLoc]
            let newValue = regAccess.write(value: value, to: regValue)
            registers[keyPath: regLoc] = newValue
            
        case let .mem(index, W):
//            var memValue = ram[index]
//            memValue = W ? value : ((memValue & 0x00FF) | (value & 0xFF00)) // TODO: where does 1 byte go: msb or lsb? Assuming left hand side - msb
//            ram[index] = memValue
            if W {
                ram[index] = UInt8((value & 0xFF00) >> 8) // big endian
                ram[index + 1] = UInt8(value & 0x00FF)
            } else {
                ram[index] = UInt8(value & 0x00FF)
            }
        }
    }
}

func readMemoryWord(index: Int) -> UInt16 {
    // big endian
    let msb = ram[index]
    let lsb = ram[index + 1]
    let result = (UInt16(msb) << 8) | UInt16(lsb)
    return result
}

func writeMemoryWord(_ value: UInt16, index: Int) {
    let msb = UInt8((value & 0xFF00) >> 8)
    let lsb = UInt8(value & 0x00FF)
    // big endian
    ram[index] = msb
    ram[index + 1] = lsb
}

enum RegAccess {
    case full
    case low
    case high
    
    func read(_ value: UInt16) -> UInt16 {
        switch self {
        case .full: return value
        case .low : return value & 0x00FF
        case .high: return value & 0xFF00
        }
    }
    
    func write(value: UInt16, to target: UInt16) -> UInt16 {
        switch self {
        case .full: return value
        case .low : return target & (0xFF00) | (value & 0x00FF)
        case .high: return target & (0x00FF) | (value & 0xFF00)
        }
    }
}


private func operationType(forOpcode opcode: Opcode) -> OperationType {
    switch opcode {
    case .short(let shortOpcode):
        
        switch shortOpcode {
        case .movImmediateToReg: return .mov
        }
        
    case .simple(let simpleOpcode):
        switch simpleOpcode {
        case .movRegMem, .moveImmediateRegMem: return .mov
        case .addRegMem, .addImmediateToAcc: return .add
        case .subRegMem, .subImmediateToAcc: return .sub
        case .cmpRegMem, .cmpImmediateToAcc: return .cmp
        }
        
    case .long(_):
        return .jmp
        
    case .composite(let compositeOpcode):
        switch compositeOpcode {
        case .AddSubCmp(let part2):
            switch part2 {
            case .add: return .add
            case .sub: return .sub
            case .cmp: return .cmp
            }
        }
    }
}



//
// Parsing
//

private func parse(data: Data) -> [Command] {
    var cmds = [Command]()
    var dataIterator = DataIterator(data: data)
    while dataIterator.hasMore {
        cmds.append(parse(dataIterator: &dataIterator))
    }
    return cmds
}


private func parse(dataIterator dataIter: inout DataIterator) -> Command {
    let b = dataIter.next()!
    
    // Check short opcode
    
    var opcode = (b & 0b1111_0000) >> 4
    
    if opcode == ShortOpcode.movImmediateToReg.rawValue {
        let W = ((b & 0b0000_1000) >> 3) != 0
        let reg = b & 0b0000_0111
        let regEnum = resolveReg(W: W, reg: reg)
        let (data0, data1) = readDataFields(wide: W, dataIterator: &dataIter)
        return Command(opcode: .short(.movImmediateToReg),
                       d: nil,
                       s: nil,
                       w: W,
                       mod: nil,
                       reg: regEnum,
                       rm: nil,
                       disp0: nil,
                       disp1: nil,
                       data0: data0,
                       data1: data1)
    }
    
    // Check simple opcode
    
    opcode = (b & 0b1111_1100) >> 2
    
    if let simpleOpcode = SimpleOpcode(rawValue: opcode) {
        if simpleOpcode.isRegMem {
            let D = ((b & 0b0000_0010) >> 1) != 0
            let W = (b & 0b0000_0001) != 0
            let (modEnum, reg, rmEnum, disp0, disp1) = parseStandard2ndByte(iter: &dataIter, W: W)
            let regEnum = resolveReg(W: W, reg: reg)
            return Command(opcode: .simple(simpleOpcode),
                           d: D,
                           s: nil,
                           w: W,
                           mod: modEnum,
                           reg: regEnum,
                           rm: rmEnum,
                           disp0: disp0,
                           disp1: disp1,
                           data0: nil,
                           data1: nil)
        }
        else if simpleOpcode.isImmediateToRegMem {
            let S = ((b & 0b0000_0010) >> 1) != 0
            let W = (b & 0b0000_0001) != 0
            let (modEnum, reg, rmEnum, disp0, disp1) = parseStandard2ndByte(iter: &dataIter, W: W)
            
            var regEnum : Reg? = nil
            if !simpleOpcode.ignoresReg {
                regEnum = resolveReg(W: W, reg: reg)
            }
            
            let (data0, data1) = readDataFields(wide: W, dataIterator: &dataIter)
            return Command(opcode: .simple(simpleOpcode),
                           d: nil,
                           s: S,
                           w: W,
                           mod: modEnum,
                           reg: regEnum,
                           rm: rmEnum,
                           disp0: disp0,
                           disp1: disp1,
                           data0: data0,
                           data1: data1)
        }
        else if simpleOpcode.isImmediateToAcc {
            let S = false
            let W = (b & 0b0000_0001) != 0
            let (data0, data1) = readDataFields(wide: W, dataIterator: &dataIter)
            return Command(opcode: .simple(simpleOpcode),
                           d: nil,
                           s: S,
                           w: W,
                           mod: nil,
                           reg: W ? .AX : .AL,
                           rm: nil,
                           disp0: nil,
                           disp1: nil,
                           data0: data0,
                           data1: data1)
        }
    }
    
    // Check composite opcode
    
    // ADD/SUB/CMP - Immediate to reg/mem
    
    if opcode == CompositeOpcode.Part1.AddSubCmpImmediate.rawValue {
        let S = ((b & 0b0000_0010) >> 1) != 0
        let W = (b & 0b0000_0001) != 0
        let (modEnum, opcodePart2, rmEnum, disp0, disp1) = parseStandard2ndByte(iter: &dataIter, W: W)
        
        let opcodeEnum = Opcode.composite(.AddSubCmp(CompositeOpcode.Part2(rawValue: opcodePart2)!))
        
        var (data0, data1) = readDataFields(wide: (!S && W), dataIterator: &dataIter)
        if S {
            let data16 = Int16(data0)
            data0 = UInt8(data16 & 0x00FF)
            data1 = UInt8((data16 >> 8) & 0x00FF)
        }
        return Command(opcode: opcodeEnum,
                       d: nil,
                       s: S,
                       w: W,
                       mod: modEnum,
                       reg: nil,
                       rm: rmEnum,
                       disp0: disp0,
                       disp1: disp1,
                       data0: data0,
                       data1: data1)
    }
    
    // Check full byte codes
    
    if let longOpcode = LongOpcode(rawValue: b) {
        let (disp0, _) = readDataFields(wide: false, dataIterator: &dataIter)
        return Command(opcode: .long(longOpcode), d: nil, s: nil, w: false, mod: nil, reg: nil, rm: nil,
                                    disp0: disp0, disp1: nil, data0: nil, data1: nil)
    }
    
     fatalError("Unhandled byte: \(b.binStr)")
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
// MARK: - Model, first pass, suitable for dissasembly
//

struct Command {
    let opcode: Opcode
    let d: Bool?
    let s: Bool?
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
    case long(LongOpcode)
    case composite(CompositeOpcode)
}

enum ShortOpcode: UInt8 {
    case movImmediateToReg = 0b1011
}

enum SimpleOpcode: UInt8 {
    
    case movRegMem = 0b100010
    case moveImmediateRegMem = 0b110001
    
    case addRegMem = 0b000000
    case addImmediateToAcc = 0b000001
    
    case subRegMem = 0b001010
    case subImmediateToAcc = 0b001011
    
    case cmpRegMem = 0b001110
    case cmpImmediateToAcc = 0b001111
}

enum LongOpcode: UInt8 {
    case JE     = 0b0111_0100 // <=> JZ
    case JL     = 0b0111_1100 // <=> JNG
    case JLE    = 0b0111_1110 // <=> JNG
    case JB     = 0b0111_0010 // <=> JNAE
    case JBE    = 0b0111_0110 // <=> JNA
    case JP     = 0b0111_1010 // <=> JPE
    case JO     = 0b0111_0000
    case JS     = 0b0111_1000
    case JNE    = 0b0111_0101 // <=> JNZ
    case JNL    = 0b0111_1101 // <=> JGE
    case JG     = 0b0111_1111 // <=> JNLE
    case JNB    = 0b0111_0011 // <=> JAE
    case JA     = 0b0111_0111 // <=> JNBE
    case JNP    = 0b0111_1011 // <=> JPO
    case JNO    = 0b0111_0001
    case JNS    = 0b0111_1001
    case LOOP   = 0b1110_0010
    case LOOPZ  = 0b1110_0001 // <=> LOOPE
    case LOOPNZ = 0b1110_0000 // <=> LOOPNE
    case JCXZ   = 0b1110_0011
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
// MARK: - Making Source ASM
//

private func makeSource(cmds: [Command]) -> String {
    var str = "bits 16\n\n"
    for cmd in cmds {
        str += makeSource(cmd: cmd)
        str += "\n"
    }
    return str
}

private func makeSource(cmd: Command) -> String {
    var str = ""
    str.append(asmString(cmd.opcode))
    
    // Check R/M first as reg might not exist
    if let rm = cmd.rm {
        let rmStr = asmRm(rm: rm, disp0: cmd.disp0, disp1: cmd.disp1)
        
        var first: String
        let second: String
        
        if let reg = cmd.reg {    // register <-> memory
            let regStr = asmString(reg)
            first = cmd.d! ? regStr : rmStr
            second = !cmd.d! ? regStr : rmStr
        }
        else {  // immediate to register/memory - constant
            first = rmStr
            second = asmData(data0: cmd.data0!, data1: cmd.data1)
            
            // word/byte, "add byte [bx], 34", examples: "add word [bp + si + 1000], 29"
            if case RM.eac(_, _) = rm {
                str.append(" " + (cmd.data1 != nil ? "WORD" : "BYTE"))
            }
        }
        
        str.append(" " + first + ", " + second)
    }
    
    else if let reg = cmd.reg { // immediate to register only - constant
        let regStr = asmString(reg)
        let dataStr = asmData(data0: cmd.data0!, data1: cmd.data1)
        str.append(" " + regStr + ", " + dataStr)
    }
    
    else if let data0 = cmd.data0 {
        let reg: Reg = cmd.w ? Reg.AX : Reg.AL
        let regStr = asmString(reg)
        let dataStr = asmData(data0: data0, data1: cmd.data1)
        str.append(" " + regStr + ", " + dataStr)
    }
    
    else if let disp0 = cmd.disp0 { // jumps
        let disp = Int8(truncatingIfNeeded: disp0)
        str.append(", \(disp)")
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
        var individualStrs = regs.map(asmString(_:))
        
        if let disp0 {
            let dispStr = asmData(data0: disp0, data1: disp1)
            if dispStr != "0" {
                individualStrs.append(dispStr)
            }
        }
        str += individualStrs.joined(separator: " + ")
        str += "]"
    }
    return str
}

private func asmData(data0: UInt8, data1: UInt8?) -> String {
    var data : UInt16 = UInt16(data0)
    var isNegative = (data & 0b0000_0000_1000_0000) != 0
    if let data1 = data1 { // 16-bit
        data = (UInt16(data1) << 8) | data
        isNegative = (data & 0b1000_0000_0000_0000) != 0
        return isNegative ? "\(Int16(truncatingIfNeeded: data))"
                          : "\(data)"
    }
    else { // 8-bit
        return isNegative ? "\(Int8(truncatingIfNeeded: data))"
                          : "\(data)"
    }
}

private func asmString(_ opcode: Opcode) -> String {
    switch opcode {
    case .short(let shortOpcode):
        switch shortOpcode {
        case .movImmediateToReg: return "MOV"
        }
    case .simple(let simpleOpcode):
        switch simpleOpcode {
        case .movRegMem, .moveImmediateRegMem: return "MOV"
        case .addRegMem, .addImmediateToAcc: return "ADD"
        case .subRegMem, .subImmediateToAcc: return "SUB"
        case .cmpRegMem, .cmpImmediateToAcc: return "CMP"
        }
    case .long(let longOpcode):
        return "\(longOpcode)"
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
// MARK: - Util
//

extension Flags: Equatable { }
extension Registers: Equatable { }

func loadFile(_ name: String) -> Data {
    let inputFileUrl = dataDirUrl.appending(path: name, directoryHint: URL.DirectoryHint.notDirectory)
    let data = try! Data(contentsOf: inputFileUrl)
    return data
}

func writeFile(_ name: String, asm: String) {
    let outputFileUrl = dataDirUrl.appending(path: name + "g.asm", directoryHint: URL.DirectoryHint.notDirectory)
    try! asm.write(to: outputFileUrl, atomically: false, encoding: .ascii)
}

struct DataIterator: IteratorProtocol {
    private let data: Data
    var index: Int {
        get {
            registers.IP
        }
        set {
            precondition(0 <= index)
            registers.IP = newValue
        }
    }
    init(data: Data) {
        self.data = data
    }
    mutating func next() -> UInt8? {
        if (index >= data.count) { return nil }
        let byte = data[index]
        index += 1
        return byte
    }
    
    var hasMore: Bool {
        (0 <= index) && (index < data.count - 1)
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
        case .moveImmediateRegMem, .addImmediateToAcc, .subImmediateToAcc, .cmpImmediateToAcc:
            return false
        }
    }
    
    var isImmediateToAcc: Bool {
        switch self {
        case .movRegMem, .moveImmediateRegMem, .addRegMem, .subRegMem, .cmpRegMem:
            return false
        case .addImmediateToAcc, .subImmediateToAcc, .cmpImmediateToAcc:
            return true
        }
    }
    
    var isImmediateToRegMem: Bool {
        switch self {
        case .moveImmediateRegMem:
            return true
        case .movRegMem, .addImmediateToAcc, .subImmediateToAcc, .cmpImmediateToAcc, .addRegMem, .subRegMem, .cmpRegMem:
            return false
        }
    }
    
    var ignoresReg: Bool {
        switch self {
        case .moveImmediateRegMem: return true
        default: return false
        }
    }
}


//
// MARK: - Printing
//

extension Registers: CustomStringConvertible {
    var description: String {
        "Registers: \nA: \(A) \nB: \(B) \nC: \(C) \nD: \(D) \nSP: \(SP) \nBP: \(BP) \nSI: \(SI) \nDI: \(DI) \nIP: \(IP) \nflags: \(flags)"
    }
}

extension Flags: CustomStringConvertible {
    var description: String {
        "Z: \(Z) S: \(S)"
    }
}

extension Command: CustomStringConvertible {
    var description: String {
        var str = ""
        str += asmString(self.opcode) + ": "
        str += "d: \(d.str) \t s: \(s.str) \t w: \(w) \t mod: \(mod.str) \t reg: \(reg.str) \t rm: \(rm.str) \t "
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
