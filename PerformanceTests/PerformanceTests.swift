import XCTest

final class PerformanceTests: XCTestCase {
    
    func test8086() {
        
        var source : String
        var binary : Data
        var dissasembled : String
        
        // reg to reg:
        source = "bits 16\n\nmov si, bx\n"
        binary = data([0b10001001, 0b11011110])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nmov dh, al\n"
        binary = data([0b10001000, 0b11000110])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // 8-bit (immediate) to reg:
        source = "bits 16\n\nmov cx, 12\n"
        binary = data([0b10111001, 0b00001100, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nmov cx, 65524\n"
        binary = data([0b10111001, 0b11110100, 0b11111111]) // TODO: -12
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // 16-bit (immediate) to register:
        source = "bits 16\n\nmov dx, 3948\n"
        binary = data([0b10111010, 0b01101100, 0b00001111])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nmov dx, 61588\n"
        binary = data([0b10111010, 0b10010100, 0b11110000]) // TODO: -3948
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // Source address calculation:
        source = "bits 16\n\nmov al, [bx + si]\n"
        binary = data([0b10001010, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nmov al, [bx + di]\n"
        binary = data([0b10001010, 0b00000001 ])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nmov al, [bp]\n"
        binary = data([0b10001010, 0b01000110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // Source 8-bit address
        source = "bits 16\n\nmov ah, [bx + si + 4]\n"
        binary = data([0b10001010, 0b01100000, 0b00000100])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // Source 16-bit address
        source = "bits 16\n\nmov al, [bx + si + 4999]\n"
        binary = data([0b10001010, 0b10000000, 0b10000111, 0b00010011])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        // Destination address
        source = "bits 16\n\nmov [bx + di], cx\n"
        binary = data([0b10001001, 0b00001001])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())

        source = "bits 16\n\nmov [bp + si], cl\n"
        binary = data([0b10001000, 0b00001010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nmov [bp], ch\n"
        binary = data([0b10001000, 0b01101110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        


        // Other commands

        source = "bits 16\n\nadd bx, [bx + si]\n"
        binary = data([0b00000011, 0b00011000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd bx, [bp]\n"
        binary = data([0b00000011, 0b01011110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd si, 2\n"
        binary = data([0b10000011, 0b11000110, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd bp, 2\n"
        binary = data([0b10000011, 0b11000101, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd cx, 8\n"
        binary = data([0b10000011, 0b11000001, 0b00001000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd bx, [bp]\n"
        binary = data([0b00000011, 0b01011110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd cx, [bx + 2]\n"
        binary = data([0b00000011, 0b01001111, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd bh, [bp + si + 41]\n"
        binary = data([0b00000010, 0b01111010, 0b00101001])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd di, [bp + di + 6]\n"
        binary = data([0b00000011, 0b01111011, 0b00000110])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd [bx + si], bx\n"
        binary = data([0b00000001, 0b00011000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd [bp], bx\n"
        binary = data([0b00000001, 0b01011110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd [bp], bx\n"
        binary = data([0b00000001, 0b01011110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd [bx + 2], cx\n"
        binary = data([0b00000001, 0b01001111, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd [bp + si + 4], bh\n"
        binary = data([0b00000000, 0b01111010, 0b00000100])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd [bp + di + 6], di\n"
        binary = data([0b00000001, 0b01111011, 0b00000110])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
//        source = "bits 16\n\nadd byte [bx], 34\n"
//        binary = data([0b10000000, 0b00000111, 0b00100010])
//        dissasembled = dissasemble(binary)
//        XCTAssertEqual(source, dissasembled.lowercased())
//
//        source = "bits 16\n\nadd word [bp + si + 1000], 29\n"
//        binary = data([0b10000011, 0b10000010, 0b11101000, 0b00000011, 0b00011101])
//        dissasembled = dissasemble(binary)
//        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd ax, [bp]\n"
        binary = data([0b00000011, 0b01000110, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd al, [bx + si]\n"
        binary = data([0b00000010, 0b00000000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd ax, bx\n"
        binary = data([0b00000001, 0b11011000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd al, ah\n"
        binary = data([0b00000000, 0b11100000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd ax, 1000\n"
        binary = data([0b00000101, 0b11101000, 0b00000011])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nadd al, 226\n" // TODO: -30
        binary = data([0b00000100, 0b11100010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nsub al, bh\n"
        binary = data([0b00101000, 0b11111000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nsub [bx + 2], cx\n"
        binary = data([0b00101001, 0b01001111, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\nsub al, 10\n"
        binary = data([0b00101100, 0b00001010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\ncmp al, bh\n"
        binary = data([0b00111000, 0b11111000])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\ncmp [bx + 2], cx\n"
        binary = data([0b00111001, 0b01001111, 0b00000010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
        
        source = "bits 16\n\ncmp ax, 10\n"
        binary = data([0b10000011, 0b11111000, 0b00001010])
        dissasembled = dissasemble(binary)
        XCTAssertEqual(source, dissasembled.lowercased())
    }
    
//    func testIndividual() {
//        var source : String
//        var binary : Data
//        var dissasembled : String
//        
//        
//    }
    
    func data(_ bytes: [UInt8]) -> Data {
        let data = Data(bytes)
        return data
    }
}
