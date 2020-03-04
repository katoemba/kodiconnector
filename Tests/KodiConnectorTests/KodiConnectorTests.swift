//
//  KodiConnectorTests.swift
//  KodiConnectorTests
//
//  Created by Berrie Kremers on 02/12/2018.
//  Copyright © 2018 Katoemba Software. All rights reserved.
//

import XCTest
@testable import KodiConnector

class KodiConnectorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testValidKodiAddressURL() {
        let namedAddress = KodiAddress(ip: "player.local.", port: 8080, websocketPort: 9090)
        
        XCTAssertTrue(namedAddress.baseUrl != nil, "Expected valid baseUrl, got nil")
        XCTAssertTrue(namedAddress.jsonRpcUrl != nil, "Expected valid baseUrl, got nil")

        let ipAddress = KodiAddress(ip: "192.168.1.7", port: 8080, websocketPort: 9090)
        
        XCTAssertTrue(ipAddress.baseUrl != nil, "Expected valid baseUrl, got nil")
        XCTAssertTrue(ipAddress.jsonRpcUrl != nil, "Expected valid baseUrl, got nil")
    }

    func testInvalidKodiAddressURL() {
        let invalidIpAddress = KodiAddress(ip: "fe80:0:0:0:b6fb:e4ff:fe2a:5e31%eth0.local.", port: 8080, websocketPort: 9090)
        
        XCTAssertTrue(invalidIpAddress.baseUrl == nil, "Expected nil baseUrl, got value")
        XCTAssertTrue(invalidIpAddress.jsonRpcUrl == nil, "Expected nil baseUrl, got value")
    }
}
