//
//  KodiWrapper+Info.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 18/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

extension KodiWrapper {
    public func getKodiVersion() -> Observable<String> {
        struct Root: Decodable {
            var result: Result
        }
        struct Result: Decodable {
            var buildVersion: String
            
            enum CodingKeys: String, CodingKey {
                case buildVersion = "System.BuildVersion"
            }
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "XBMC.GetInfoLabels",
                          "params": ["labels": ["System.BuildVersion"]],
                          "id": "buildVersion"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> String in
                let json = try JSONDecoder().decode(Root.self, from: data)
                return json.result.buildVersion
            })
            .catchError({ (error) -> Observable<String> in
                Observable.just("Unknown")
            })
    }

    public func getApiVersion() -> Observable<String> {
        struct Root: Decodable {
            var result: Result
        }
        struct Result: Decodable {
            var version: Version
        }
        struct Version: Decodable {
            var major: Int
            var minor: Int
            var patch: Int
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "JSONRPC.Version",
                          "id": "apiVersion"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> String in
                let json = try JSONDecoder().decode(Root.self, from: data)
                return "\(json.result.version.major).\(json.result.version.minor).\(json.result.version.patch)"
            })
            .catchError({ (error) -> Observable<String> in
                Observable.just("0.0.0")
            })
    }

    public func getApplicationProperties() -> Observable<(String, String, Int)> {
        struct Root: Decodable {
            var result: Properties
        }
        struct Properties: Decodable {
            var name: String
            var version: Version
            var volume: Int
        }
        struct Version: Decodable {
            var major: Int
            var minor: Int
            var revision: String
            var tag: String
            
            var description: String {
                return "\(major):\(minor):\(revision) \(tag)"
            }
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "Application.GetProperties",
                          "params": ["properties": ["volume", "name", "version"]],
                          "id": "getProperties"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (String, String, Int) in
                let json = try JSONDecoder().decode(Root.self, from: data)
                
                return (json.result.name, json.result.version.description, json.result.volume)
            })
            .catchError({ (error) -> Observable<(String, String, Int)> in
                Observable.empty()
            })
    }
}
