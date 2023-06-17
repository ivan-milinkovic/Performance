//
//  JsonParserTests.swift
//  PerformanceTests
//
//  Created by Ivan Milinkovic on 17.6.23..
//

import XCTest

final class JsonParserTests: XCTestCase {
    
    var jsonParser : JsonParser!
    
    override func setUp() async throws {
        jsonParser = JsonParser()
    }
    
    override func tearDown() async throws {
        jsonParser = nil
    }
    
    func testSingleValueLiteral() throws {
        var result : Any
        
        result = jsonParser.parse(jsonString: "123.234")
        XCTAssertEqual(result as? Double, 123.234)
        
        result = jsonParser.parse(jsonString: "123")
        XCTAssertEqual(result as? Double, 123)
        
        result = jsonParser.parse(jsonString: #""hello""#) // hello in quotes
        XCTAssertEqual(result as? String, "hello")
        
        result = jsonParser.parse(jsonString: "null")
        XCTAssertEqual(result as? NSNull, NSNull())
        
        result = jsonParser.parse(jsonString: "true")
        XCTAssertEqual(result as? Bool, true)
        
        result = jsonParser.parse(jsonString: "True")
        XCTAssertEqual(result as? Bool, true)
        
        result = jsonParser.parse(jsonString: "TRUE")
        XCTAssertEqual(result as? Bool, true)
        
        result = jsonParser.parse(jsonString: "false")
        XCTAssertEqual(result as? Bool, false)
        
        result = jsonParser.parse(jsonString: "False")
        XCTAssertEqual(result as? Bool, false)
        
        result = jsonParser.parse(jsonString: "FALSE")
        XCTAssertEqual(result as? Bool, false)
    }
    
    func testMap() throws {
        
        var json: String
        var result: Any
        var map: Dictionary<String, Any>
        
        json = """
        { }
        """
        result = jsonParser.parse(jsonString: json)
        map = try XCTUnwrap(result as? Dictionary<String, Any>)
        XCTAssertEqual(map.count, 0)
        
        json = """
        { "key" : "value" }
        """
        result = jsonParser.parse(jsonString: json)
        map = try XCTUnwrap(result as? Dictionary<String, Any>)
        XCTAssertEqual(map.count, 1)
        XCTAssertEqual(map["key"] as? String, "value")
        
        json = """
        {
            "key1" : "value1",
            "key2" : 123,
            "key3" : true,
            "key4" : null
        }
        """
        result = jsonParser.parse(jsonString: json)
        map = try XCTUnwrap(result as? Dictionary<String, Any>)
        XCTAssertEqual(map.count, 4)
        XCTAssertEqual(map["key1"] as? String, "value1")
        XCTAssertEqual(map["key2"] as? Double, 123)
        XCTAssertEqual(map["key3"] as? Bool, true)
        XCTAssertEqual(map["key4"] as? NSNull, NSNull())
    }

    func testArray() throws {
        var json: String
        var result: Any
        var array: Array<Any>

        json = "[ ]"
        result = jsonParser.parse(jsonString: json)
        array = try XCTUnwrap(result as? Array<Any>)
        XCTAssertEqual(array.count, 0)
        
        json = "[ 123 ]"
        result = jsonParser.parse(jsonString: json)
        array = try XCTUnwrap(result as? Array<Any>)
        XCTAssertEqual(array.count, 1)
        
        json = """
        [ "123", 123, true, null ]
        """
        result = jsonParser.parse(jsonString: json)
        array = try XCTUnwrap(result as? Array<Any>)
        XCTAssertEqual(array.count, 4)
        XCTAssertEqual(array[0] as? String, "123")
        XCTAssertEqual(array[1] as? Double, 123)
        XCTAssertEqual(array[2] as? Bool, true)
        XCTAssertEqual(array[3] as? NSNull, NSNull())
    }
    
    func testNested() throws {
        var json: String
        var result: Any
        var map: Dictionary<String, Any>
        
        json = """
        {
            "key1" : [
                "123", 123, true, null
            ],
            "key2" : {
                "key1" : "value1",
                "key2" : 123,
                "key3" : true,
                "key4" : null
            },
            "key3" : null
        }
        """
        result = jsonParser.parse(jsonString: json)
        map = try XCTUnwrap(result as? Dictionary<String, Any>)
        XCTAssertEqual(map.count, 3)
        
        let a = try XCTUnwrap(map["key1"] as? Array<Any>)
        XCTAssertEqual(a.count, 4)
        XCTAssertEqual(a[0] as? String, "123")
        XCTAssertEqual(a[1] as? Double, 123)
        XCTAssertEqual(a[2] as? Bool, true)
        XCTAssertEqual(a[3] as? NSNull, NSNull())
        
        let d1 = try XCTUnwrap(map["key2"] as? Dictionary<String, Any>)
        XCTAssertEqual(d1.count, 4)
        XCTAssertEqual(d1["key1"] as? String, "value1")
        XCTAssertEqual(d1["key2"] as? Double, 123)
        XCTAssertEqual(d1["key3"] as? Bool, true)
        XCTAssertEqual(d1["key4"] as? NSNull, NSNull())
        
        XCTAssertEqual(map["key3"] as? NSNull, NSNull())
    }
    
    func testNoValue() throws {
        let result = jsonParser.parse(jsonString: " ")
        XCTAssertEqual(result as? NSNull, NSNull())
    }
    
//    func testPerformanceExample() throws {
//        self.measure {
//
//        }
//    }

}