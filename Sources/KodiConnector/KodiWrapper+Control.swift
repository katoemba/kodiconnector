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
    public func play() -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.PlayPause",
                          "params": ["playerid": playerId, "play": true],
                          "id": "play"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }

    public func pause() -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.PlayPause",
                          "params": ["playerid": playerId, "play": false],
                          "id": "pause"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }

    public func stop() -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.Stop",
                          "params": ["playerid": playerId],
                          "id": "stop"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, data) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }

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
                print(error)
                return Observable.just(false)
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
                print(error)
                return Observable.just(false)
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
                print(error)
                return Observable.just(false)
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
                print(error)
                return Observable.just(false)
            })
    }
    
    public func setShuffle(_ on: Bool) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.SetShuffle",
                          "params": ["playerid": playerId, "shuffle": on],
                          "id": "setShuffle"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }
    
    public func toggleShuffle() -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.SetShuffle",
                          "params": ["playerid": playerId, "shuffle": "toggle"],
                          "id": "setShuffle"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }
    
    public func setRepeat(_ mode: String) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.SetRepeat",
                          "params": ["playerid": playerId, "repeat": mode],
                          "id": "setRepeat"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }
    
    public func cycleRepeat() -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.SetRepeat",
                          "params": ["playerid": playerId, "repeat": "cycle"],
                          "id": "setRepeat"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }

    public func setVolume(_ volume: Float) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Application.SetVolume",
                          "params": ["volume": max(min(Int(volume * 100.0), 100), 0)],
                          "id": "setVolume"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }

    public func seek(_ position: UInt32) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.Seek",
                          "params": ["playerid": playerId, "value": ["hours": Int(position / 3600),
                                                                     "minutes": Int((position % 3600) / 60),
                                                                     "seconds": Int(position % 60),
                                                                     "milliseconds": 0]],
                          "id": "seek"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .debug("seek")
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }

    public func seek(_ percentage: Float) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.Seek",
                          "params": ["playerid": playerId, "value": max(min(percentage * 100.0, 100.0), 0.0)],
                          "id": "seek"] as [String : Any]
        
        return dataPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                print(error)
                return Observable.just(false)
            })
    }
}
