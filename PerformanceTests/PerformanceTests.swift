import XCTest

final class PerformanceTests: XCTestCase {
    
    override func setUp() async throws {
        reset()
    }
    
    override func tearDown() async throws {
        reset()
    }
    
    func data(_ bytes: [UInt8]) -> Data {
        let data = Data(bytes)
        return data
    }
    
    func test8086Asm() {
        
        var source : String
        var binary : Data
        var dissasembled : String
        
        // reg to reg:
        reset()
        source = "bits 16\n\nmov si, bx\n"
        binary = data([0b10001001, 0b11011110])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nmov dh, al\n"
        binary = data([0b10001000, 0b11000110])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // 8-bit (immediate) to reg:
        reset()
        source = "bits 16\n\nmov cl, 12\n"
        binary = data([0b10110001, 0b00001100])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        reset()
        source = "bits 16\n\nmov cx, 12\n"
        binary = data([0b10111001, 0b00001100, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nmov cx, -12\n"
        binary = data([0b10111001, 0b11110100, 0b11111111])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // 16-bit (immediate) to register:
        reset()
        source = "bits 16\n\nmov dx, 3948\n"
        binary = data([0b10111010, 0b01101100, 0b00001111])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nmov dx, -3948\n"
        binary = data([0b10111010, 0b10010100, 0b11110000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // Source address calculation:
        reset()
        source = "bits 16\n\nmov al, [bx + si]\n"
        binary = data([0b10001010, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nmov al, [bx + di]\n"
        binary = data([0b10001010, 0b00000001 ])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nmov al, [bp]\n"
        binary = data([0b10001010, 0b01000110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // Source 8-bit address
        reset()
        source = "bits 16\n\nmov ah, [bx + si + 4]\n"
        binary = data([0b10001010, 0b01100000, 0b00000100])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // Source 16-bit address
        reset()
        source = "bits 16\n\nmov al, [bx + si + 4999]\n"
        binary = data([0b10001010, 0b10000000, 0b10000111, 0b00010011])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // Destination address
        reset()
        source = "bits 16\n\nmov [bx + di], cx\n"
        binary = data([0b10001001, 0b00001001])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        reset()
        source = "bits 16\n\nmov [bp + si], cl\n"
        binary = data([0b10001000, 0b00001010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nmov [bp], ch\n"
        binary = data([0b10001000, 0b01101110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        


        // Other commands
        
        reset()
        source = "bits 16\n\nadd bx, [bx + si]\n"
        binary = data([0b00000011, 0b00011000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd bx, [bp]\n"
        binary = data([0b00000011, 0b01011110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd si, 2\n"
        binary = data([0b10000011, 0b11000110, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd bp, 2\n"
        binary = data([0b10000011, 0b11000101, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd cx, 8\n"
        binary = data([0b10000011, 0b11000001, 0b00001000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd bx, [bp]\n"
        binary = data([0b00000011, 0b01011110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd cx, [bx + 2]\n"
        binary = data([0b00000011, 0b01001111, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd bh, [bp + si + 41]\n"
        binary = data([0b00000010, 0b01111010, 0b00101001])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd di, [bp + di + 6]\n"
        binary = data([0b00000011, 0b01111011, 0b00000110])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd [bx + si], bx\n"
        binary = data([0b00000001, 0b00011000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd [bp], bx\n"
        binary = data([0b00000001, 0b01011110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd [bp], bx\n"
        binary = data([0b00000001, 0b01011110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd [bx + 2], cx\n"
        binary = data([0b00000001, 0b01001111, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd [bp + si + 4], bh\n"
        binary = data([0b00000000, 0b01111010, 0b00000100])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd [bp + di + 6], di\n"
        binary = data([0b00000001, 0b01111011, 0b00000110])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
//        reset()
//        source = "bits 16\n\nadd byte [bx], 34\n"
//        binary = data([0b10000000, 0b00000111, 0b00100010])
//        dissasembled = dissasemble(binary)
//        XCTAssertEqual(source, dissasembled.lowercased())
//
//        reset()
//        source = "bits 16\n\nadd word [bp + si + 1000], 29\n"
//        binary = data([0b10000011, 0b10000010, 0b11101000, 0b00000011, 0b00011101])
//        dissasembled = dissasemble(binary)
//        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd ax, [bp]\n"
        binary = data([0b00000011, 0b01000110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd al, [bx + si]\n"
        binary = data([0b00000010, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd ax, bx\n"
        binary = data([0b00000001, 0b11011000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd al, ah\n"
        binary = data([0b00000000, 0b11100000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd ax, 1000\n"
        binary = data([0b00000101, 0b11101000, 0b00000011])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd al, -30\n"
        binary = data([0b00000100, 0b11100010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nadd bp, 1027\n"
        binary = data([0b10000001, 0b11000101, 0b00000011, 0b00000100])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nsub al, bh\n"
        binary = data([0b00101000, 0b11111000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nsub [bx + 2], cx\n"
        binary = data([0b00101001, 0b01001111, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\nsub al, 10\n"
        binary = data([0b00101100, 0b00001010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\ncmp al, bh\n"
        binary = data([0b00111000, 0b11111000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\ncmp [bx + 2], cx\n"
        binary = data([0b00111001, 0b01001111, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\ncmp ax, 10\n"
        binary = data([0b10000011, 0b11111000, 0b00001010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        reset()
        source = "bits 16\n\njne, -2\n"
        binary = data([0b01110101, 0b11111110])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
    }
    
    func testAsmFile38() {
        let file = "listing_0038_many_register_mov"
        let data = loadFile(file)
        let asm = dissasemble(data)
        
        let expectedAsm = String.init(data: loadFile(file + "_clean.asm"), encoding: .ascii)
        XCTAssertEqual(asm.lowercased(), expectedAsm)
    }
    
    func testAsmFile39() {
        let file = "listing_0039_more_movs"
        let data = loadFile(file)
        let asm = dissasemble(data)
        
        let expectedAsm = String.init(data: loadFile(file + "_clean.asm"), encoding: .ascii)
        XCTAssertEqual(asm.lowercased(), expectedAsm)
    }
    
    func testIndividualAsm() {
        var source : String
        var binary : Data
        var dissasembled : String

        source = "bits 16\n\nmov al, [bx + si + 4999]\n"
        binary = data([0b10001010, 0b10000000, 0b10000111, 0b00010011])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
    }
    
    func testRunBinary() {
        var binary: Data
        
        // mov dx, [bp]
        reset()
        registers.BP = 0
        writeMemoryWord(10, index: Int(registers.BP))
        binary = data([0b10001011, 0b01010110, 0b00000000])
        runBinary(binary)
        XCTAssertEqual(registers.D, 10)
        
        // mov si, bx
        reset()
        registers.B = 10
        binary = data([0b10001001, 0b11011110])
        runBinary(binary)
        XCTAssertEqual(registers.SI, 10)
        
        // mov cl, 12
        reset()
        binary = data([0b10110001, 0b00001100])
        runBinary(binary)
        XCTAssertEqual(registers.C, 12)
        
        // add ax, 1000
        reset()
        binary = data([0b00000101, 0b11101000, 0b00000011])
        runBinary(binary)
        XCTAssertEqual(registers.A, 1000)
    }
    
    // fails if run with others
//    func testRunnningListing41() {
//        reset()
//        let data = loadFile("listing41_add_sub_cmp")
//        runBinary(data)
//        let expected = Registers(A: 65528, B: 65520, C: 0, D: 0, SP: 0, BP: 0, SI: 0, DI: 0) // no reference, is it correct?
//        XCTAssertEqual(registers, expected)
//    }
    
    func testRunningListing43() {
        reset()
        let data = loadFile("listing_0043_immediate_movs")
        runBinary(data)
        let expected = Registers(A: 1, B: 2, C: 3, D: 4, SP: 5, BP: 6, SI: 7, DI: 8, IP: 24, flags: Flags(Z: false, S: false))
        XCTAssertEqual(registers, expected)
    }
    
    func testRunnningListing44() {
        reset()
        let data = loadFile("listing_0044_register_movs")
        runBinary(data)
        let expected = Registers(A: 4, B: 3, C: 2, D: 1, SP: 1, BP: 2, SI: 3, DI: 4, IP: 28, flags: Flags(Z: false, S: false))
        XCTAssertEqual(registers, expected)
    }
    
    func testRunnningListing46() {
        reset()
        let data = loadFile("listing_0046_add_sub_cmp")
        runBinary(data)
        let expected = Registers(A: 0, B: 57602, C: 3841, D: 0, SP: 998, BP: 0, SI: 0, DI: 0, IP: 24, flags: Flags(Z: true, S: false))
        XCTAssertEqual(registers, expected)
    }
    
    func testRunnningListing48() {
        reset()
        let data = loadFile("listing_0048_ip_register")
        runBinary(data)
        let expected = Registers(A: 0, B: 2000, C: 64736, D: 0, SP: 0, BP: 0, SI: 0, DI: 0, IP: 14, flags: Flags(Z: false, S: true))
        XCTAssertEqual(registers, expected)
    }
    
    func testRunnningListing49() {
        reset()
        let data = loadFile("listing_0049_conditional_jumps")
        runBinary(data)
        let expected = Registers(A: 0, B: 1030, C: 0, D: 0, SP: 0, BP: 0, SI: 0, DI: 0, IP: 14, flags: Flags(Z: true, S: false))
        XCTAssertEqual(registers, expected)
    }
    
    func testRun1Binary() {
        reset()
        var binary: Data
        
        // mov dx, [bp]
        registers.BP = 0
        writeMemoryWord(10, index: Int(registers.BP))
        binary = data([0b10001011, 0b01010110, 0b00000000])
        runBinary(binary)
        XCTAssertEqual(registers.D, 10)
    }
    
    func reset() {
        registers.A = 0
        registers.B = 0
        registers.C = 0
        registers.D = 0
        registers.SP = 0
        registers.BP = 0
        registers.SI = 0
        registers.DI = 0
        registers.IP = 0
        registers.flags.S = false
        registers.flags.Z = false
        registers.flags.S = false
        registers.flags.O = false
        registers.flags.C = false
        registers.flags.P = false
    }
}

