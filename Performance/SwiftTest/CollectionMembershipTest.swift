import Foundation

func testCollectionMembership() {
//    testWhitespace()
    testLarge()
}

func testWhitespace() {
    
    let char = Character("a")

    let space = Character(" ")
    let newLine = Character("\n")
    let creturn = Character("\r")
    let whitespaceCollection = [space, newLine, creturn]
    let whitespacesString = String(whitespaceCollection)
    let N = 1000
    
    var t = ContinuousClock().measure {
        var i = 0; while i < N { i += 1
            _ = whitespacesString.contains(char)
        }
    }
    print(t)
    t = ContinuousClock().measure {
        var i = 0; while i < N { i += 1
            _ = whitespaceCollection.contains(char)
        }
    }
    print(t)
    
    t = ContinuousClock().measure {
        var i = 0; while i < N { i += 1
            _ =    char == space
                || char == newLine
                || char == creturn
        }
    }
    print(t)
}

func testLarge() {
    let str =
//    "Lorem ipsum dolor sit amet, consectetur adipiscing elit"
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    
    let char = Character("a")
    let charArray = Array(str)
    let N = 1000
    
    var t = ContinuousClock().measure {
        var i = 0; while i < N { i += 1
            _ = str.contains(char)
        }
    }
    print(t)
    
    t = ContinuousClock().measure {
        var i = 0; while i < N { i += 1
            _ = charArray.contains(char)
        }
    }
    print(t)
}
