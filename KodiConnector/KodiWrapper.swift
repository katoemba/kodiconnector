//
//  KodiWrapper.swift
//  KodiConnector_iOS
//
//  Created by Berrie Kremers on 12/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxAlamofire
import Alamofire
import SwiftyJSON
import ConnectorProtocol

public class KodiWrapper: KodiProtocol {
    private let encoding = JSONEncoding.default
    private let headers = ["Content-Type": "application/json"]
    private var kodi: KodiAddress
    private var playerId = -1
    
    private var bag = DisposeBag()
    
    private func jsonPostRequest(_ url: URL, parameters: [String: Any]) -> Observable<(HTTPURLResponse, Any)> {
        return RxAlamofire.requestJSON(.post, url, parameters: parameters, encoding: encoding, headers: headers)
    }
    
    public init(kodi: KodiAddress) {
        self.kodi = kodi
        getActivePlayers()
            .filter({ (_, found) -> Bool in
                found == true
            })
            .subscribe(onNext: { [weak self] (playerId, found) in
                self?.playerId = playerId
            })
            .disposed(by: bag)
    }
    
    // MARK: - Player and status functions

    public func pong() -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "JSONRPC.Ping",
                          "id": "ping"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> Bool in
                let dict = JSON(json)
                return dict["result"].stringValue == "pong"
            })
            .catchError({ (error) -> Observable<Bool> in
                Observable.just(false)
            })
    }
    
    public func getKodiVersion() -> Observable<String> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "XBMC.GetInfoLabels",
                          "params": ["labels": ["System.BuildVersion"]],
                          "id": "buildVersion"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> String in
                let dict = JSON(json)
                return dict["result"]["System.BuildVersion"].stringValue
            })
            .catchError({ (error) -> Observable<String> in
                Observable.just("Unknown")
            })
    }
    
    public func getApiVersion() -> Observable<String> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "JSONRPC.Version",
                          "id": "apiVersion"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> String in
                let dict = JSON(json)
                return "\(dict["result"]["version"]["major"].stringValue).\(dict["result"]["version"]["minor"].stringValue).\(dict["result"]["version"]["patch"].stringValue)"
            })
            .catchError({ (error) -> Observable<String> in
                Observable.just("0.0.0")
            })
    }

    public func getActivePlayers() -> Observable<(Int, Bool)> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.GetActivePlayers",
                          "id": "getActivePlayers"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Int, Bool) in
                let dict = JSON(json)
                return (dict["result"][0]["playerid"].intValue, (dict["result"][0]["type"] == "audio"))
            })
            .catchError({ (error) -> Observable<(Int, Bool)> in
                Observable.empty()
            })
    }
    
    public func getAudioPlaylist() -> Observable<Int> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.GetPlaylists",
                          "id": "getPlaylists"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Int) in
                let dict = JSON(json)
                
                for playlist in dict["result"].arrayValue {
                    if playlist["type"].stringValue == "audio" {
                        return playlist["playlistid"].intValue
                    }
                }
                
                return 0
            })
            .catchError({ (error) -> Observable<(Int)> in
                Observable.just(0)
            })
    }
    
    public func getPlayerProperties() -> Observable<KodiPlayerProperties> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.GetProperties",
                          "params": ["playerid": playerId, "properties": ["position", "time", "totaltime", "canseek", "type", "shuffled", "repeat", "speed", "playlistid"]],
                          "id": "getPlayerProperties"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (KodiPlayerProperties) in
                let dict = JSON(json)
                var properties = KodiPlayerProperties()
                
                properties.position = dict["result"]["position"].intValue
                properties.elapsedTime = dict["result"]["time"]["hours"].intValue * 3600 +
                    dict["result"]["time"]["minutes"].intValue * 60 +
                    dict["result"]["time"]["seconds"].intValue
                properties.totalTime = dict["result"]["totaltime"]["hours"].intValue * 3600 +
                    dict["result"]["time"]["totaltime"].intValue * 60 +
                    dict["result"]["time"]["totaltime"].intValue
                properties.canSeek = dict["result"]["canseek"].boolValue
                properties.type = dict["result"]["type"].stringValue
                properties.shuffled = dict["result"]["shuffled"].boolValue
                properties.repeat = dict["result"]["repeat"].stringValue
                properties.speed = dict["result"]["speed"].intValue
                properties.playlistId = dict["result"]["playlistid"].intValue
                
                return properties
            })
            .catchError({ (error) -> Observable<KodiPlayerProperties> in
                Observable.just(KodiPlayerProperties())
            })
    }
    
    private func songFromJSON(_ dict: JSON, position: Int = 0) -> Song {
        var song = Song()
        
        if dict["songid"].int != nil {
            song.id = "\(dict["songid"].intValue)"
        }
        else if dict["id"].int != nil {
            song.id = "\(dict["id"].intValue)"
        }
        song.album = dict["album"].stringValue
        song.artist = dict["displayartist"].stringValue
        song.albumartist = dict["albumartist"][0].stringValue
        song.title = dict["label"].stringValue
        song.year = dict["year"].intValue
        song.length = dict["duration"].intValue
        song.coverURI = CoverURI.fullPathURI("http://\(kodi.ip):\(kodi.port)/image/\(dict["thumbnail"].stringValue.addingPercentEncoding(withAllowedCharacters: .letters)!)")
        song.position = position
        
        return song
    }

    public func getCurrentSong() -> Observable<Song> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.GetItem",
                          "params": ["playerid": playerId, "properties": ["album", "displayartist", "albumartist", "duration", "track", "thumbnail", "year"]],
                          "id": "getCurrentSong"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Song) in
                return self.songFromJSON(JSON(json)["result"]["item"])
            })
            .catchError({ (error) -> Observable<Song> in
                Observable.just(Song())
            })
    }
    
    public func getPlayQueue(start: Int, end: Int) -> Observable<[Song]> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.GetItems",
                          "params": ["playlistid": 0,
                                     "properties": ["album", "displayartist", "albumartist", "duration", "track", "thumbnail", "year"],
                                     "limits": ["start": start, "end": end]],
                          "id": "getPlaylistItems"] as [String : Any]
        
        print("\(parameters)")
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> ([Song]) in
                var position = JSON(json)["result"]["limits"]["start"].intValue
                var songs = [Song]()
                
                for songJson in JSON(json)["result"]["items"].arrayValue {
                    if songJson["type"] == "song" {
                        songs.append(self.songFromJSON(songJson, position: position))
                        position += 1
                    }
                }
                return songs
            })
            .catchError({ (error) -> Observable<[Song]> in
                Observable.just([])
            })
    }

    // MARK: - Player control functions

    public func togglePlayPause() -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.PlayPause",
                          "params": ["playerid": playerId],
                          "id": "playPause"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
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
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
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
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
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
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                Observable.just(false)
            })
    }
    
    public func clearPlayqueue(_ playlistId: Int) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Playlist.Clear",
                          "params": ["playlistid": playlistId],
                          "id": "playlistClear"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                Observable.just(false)
            })
    }
    
    public func playAlbum(_ album: Album, shuffle: Bool) -> Observable<Bool> {
        let parameters = ["jsonrpc": "2.0",
                          "method": "Player.Open",
                          "params": ["item": ["albumid": Int(album.id) ?? 0],
                                     "options": ["shuffled": shuffle]],
                          "id": "playAlbum"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> (Bool) in
                return true
            })
            .catchError({ (error) -> Observable<(Bool)> in
                Observable.just(false)
            })
    }
    
    // MARK: - Browse functions

    private func albumFromJSON(_ dict: JSON) -> Album {
        var album = Album()
        
        if dict["albumid"].int != nil {
            album.id = "\(dict["albumid"].intValue)"
        }
        else if dict["id"].int != nil {
            album.id = "\(dict["id"].intValue)"
        }
        album.artist = dict["artist"][0].stringValue
        album.title = dict["label"].stringValue
        album.year = dict["year"].intValue
        album.coverURI = CoverURI.fullPathURI("http://\(kodi.ip):\(kodi.port)/image/\(dict["thumbnail"].stringValue.addingPercentEncoding(withAllowedCharacters: .letters)!)")

        return album
    }
    
    public func getRecentAlbums(count: Int) -> Observable<[Album]> {
        let kodi = self.kodi
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetRecentlyAddedAlbums",
                          "params": ["properties": ["artist", "thumbnail", "year"],
                                     "limits": ["start": 0, "end": count],
                                     "sort": ["order": "descending", "method": "date"]],
                          "id": "getRecentAlbums"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> ([Album]) in
                let dict = JSON(json)
                
                var albums = [Album]([])
                for albumDict in dict["result"]["albums"].array ?? [] {
                    albums.append(self.albumFromJSON(albumDict))
                }

                return albums
            })
            .catchError({ (error) -> Observable<[Album]> in
                Observable.just([])
            })
    }

    public func getAlbums(start: Int, end: Int) -> Observable<[Album]> {
        let kodi = self.kodi
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetAlbums",
                          "params": ["properties": ["artist", "thumbnail", "year"],
                                     "limits": ["start": start, "end": end],
                                     "sort": ["order": "ascending", "method": "artist"]],
                          "id": "getAlbums"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> ([Album]) in
                let dict = JSON(json)
                
                var albums = [Album]([])
                for albumDict in dict["result"]["albums"].arrayValue {
                    albums.append(self.albumFromJSON(albumDict))
                }
                
                return albums
            })
            .catchError({ (error) -> Observable<[Album]> in
                Observable.just([])
            })
    }
    
    private func getSongsWithFilter(_ filter: [String: Any]) -> Observable<[Song]> {
        let kodi = self.kodi
        let parameters = ["jsonrpc": "2.0",
                          "method": "AudioLibrary.GetSongs",
                          "params": ["properties": ["album", "displayartist", "albumartist", "duration", "track", "thumbnail", "year"],
                                     "filter": filter,
                                     "sort": ["order": "ascending", "method": "track"]],
                          "id": "getSongsOnAlbum"] as [String : Any]
        
        return jsonPostRequest(kodi.jsonRpcUrl, parameters: parameters)
            .map({ (response, json) -> ([Song]) in
                let dict = JSON(json)
                
                var songs = [Song]([])
                for songJSON in dict["result"]["songs"].array ?? [] {
                    songs.append(self.songFromJSON(songJSON))
                }
                
                return songs
            })
            .catchError({ (error) -> Observable<[Song]> in
                Observable.just([])
            })
    }
    
    public func getSongsOnAlbum(_ album: Album) -> Observable<[Song]> {
        return getSongsWithFilter(["and": [["field": "album",
                                            "operator": "is",
                                            "value": album.title],
                                           ["field": "albumartist",
                                            "operator": "is",
                                            "value": album.artist]]])
    }
    
    public func getSongsInPlaylist(_ playlist: Playlist) -> Observable<[Song]> {
        return getSongsWithFilter(["field": "playlist",
                                   "operator": "is",
                                   "value": playlist.id])
    }
    
}
