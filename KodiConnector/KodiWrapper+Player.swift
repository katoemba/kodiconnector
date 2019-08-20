//
//  KodiWrapper+Player.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 18/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

extension KodiWrapper {
    public func pong() -> Observable<Bool> {
        struct Root: Decodable {
            var result: String
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "JSONRPC.Ping",
                          "id": "ping"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> Bool in
                let json = try JSONDecoder().decode(Root.self, from: data)
                return json.result == "pong"
            })
            .catchError({ (error) -> Observable<Bool> in
                Observable.just(false)
            })
    }
    
    public func getActivePlayers() -> Observable<(Int, Bool)> {
        struct Root: Decodable {
            var result: [Player]
        }
        struct Player: Decodable {
            var playerid: Int
            var type: String
        }
        enum MyError: Error {
            case activePlayerError
        }
        
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.GetActivePlayers",
                          "id": "getActivePlayers"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Int, Bool) in
                let json = try JSONDecoder().decode(Root.self, from: data)
                
                if json.result.count > 0 {
                    return (json.result[0].playerid, json.result[0].type == "audio")
                }
                else {
                    throw MyError.activePlayerError
                }
            })
            .catchError({ (error) -> Observable<(Int, Bool)> in
                Observable.empty()
            })
    }
}
