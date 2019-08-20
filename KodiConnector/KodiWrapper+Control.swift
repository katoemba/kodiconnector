//
//  KodiWrapper+Control.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 18/08/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

extension KodiWrapper {
    public func togglePlayPause() -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.PlayPause",
                          "params": ["playerid": playerId],
                          "id": "playPause"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                Observable.just(false)
            })
    }
    
    public func back() -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.GoTo",
                          "params": ["playerid": playerId, "to": "previous"],
                          "id": "back"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                Observable.just(false)
            })
    }
    
    public func skip() -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.GoTo",
                          "params": ["playerid": playerId, "to": "next"],
                          "id": "skip"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                Observable.just(false)
            })
    }
    
    public func goto(_ index: Int) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.GoTo",
                          "params": ["playerid": playerId, "to": index],
                          "id": "goto"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                Observable.just(false)
            })
    }
}
