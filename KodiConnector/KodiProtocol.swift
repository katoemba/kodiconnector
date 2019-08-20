//
//  KodiProtocol.swift
//  KodiConnector_iOS
//
//  Created by Berrie Kremers on 12/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

public struct KodiAddress {
    var ip: String
    var port: Int
    
    public var baseUrl: URL {
        return URL(string: "http://\(ip):\(port)/")!
    }

    public var jsonRpcUrl: URL {
        return URL(string: "http://\(ip):\(port)/jsonrpc")!
    }
}

public struct KodiPlayerProperties: Decodable {
    public struct Time: Decodable {
        var hours: Int
        var milliseconds: Int
        var minutes: Int
        var seconds: Int
        
        var timeInSeconds: Int {
            get {
                return hours * 3600 + minutes * 60 + seconds
            }
        }
    }

    var canseek: Bool
    var playlistid: Int
    var position: Int
    var `repeat`: String
    var shuffled: Bool
    var speed: Int
    var time: Time
    var totaltime: Time
    var type: String
}

public struct Limits: Decodable {
    var start: Int
    var end: Int
    var total: Int
}

public struct KodiSong: Decodable {
    var id: Int?
    var songid: Int?
    var file: String
    var label: String
    var displayartist: String
    var album: String
    var albumartist: [String]
    var duration: Int
    var year: Int
    var track: Int
    var genre: [String]
    var thumbnail: String
    
    var uniqueId: Int {
        get {
            return songid ?? id ?? 0
        }
    }
}

public struct KodiAlbum: Decodable {
    var id: Int?
    var albumid: Int?
    var displayartist: String
    var label: String
    var year: Int
    var genre: [String]
    var thumbnail: String

    var uniqueId: Int {
        return albumid ?? id ?? 0
    }
}
public struct KodiAlbums: Decodable {
    var albums: [KodiAlbum]
    var limits: Limits
}

public struct KodiArtist: Decodable {
    var id: Int?
    var artistid: Int?
    var label: String
    var thumbnail: String

    var uniqueId: Int {
        return artistid ?? id ?? 0
    }
}
public struct KodiArtists: Decodable {
    var artists: [KodiArtist]
    var limits: Limits
}

public struct KodiGenre: Decodable {
    var id: Int?
    var genreid: Int?
    var label: String
    
    var uniqueId: Int {
        return genreid ?? id ?? 0
    }
}
public struct KodiGenres: Decodable {
    var genres: [KodiGenre]
    var limits: Limits
}

public protocol KodiProtocol {
    func getKodiVersion() -> Observable<String>
    func getApiVersion() -> Observable<String>
    
    func pong() -> Observable<Bool>
    func getActivePlayers() -> Observable<(Int, Bool)>
    
    func getAudioPlaylist() -> Observable<Int>
    func getPlayerProperties() -> Observable<KodiPlayerProperties>
    
    func getPlayQueue(start: Int, end: Int) -> Observable<[KodiSong]>
    func clearPlayqueue(_ playlistId: Int) -> Observable<Bool>
    
    func togglePlayPause() -> Observable<Bool>
    func back() -> Observable<Bool>
    func skip() -> Observable<Bool>
    func goto(_ index: Int) -> Observable<Bool>
    
    func getCurrentSong() -> Observable<KodiSong>
    func getSongsOnAlbum(_ albumid: Int) -> Observable<[KodiSong]>

    func getRecentAlbums(count: Int) -> Observable<KodiAlbums>
    func getAlbums(start: Int, end: Int) -> Observable<KodiAlbums>
    func getAlbums(artistid: Int) -> Observable<KodiAlbums>
    func getAlbums(genreid: Int) -> Observable<KodiAlbums>
    func playAlbum(_ albumid: Int, shuffle: Bool) -> Observable<Bool>
    
    func getArtists(start: Int, end: Int, albumartistsonly: Bool) -> Observable<KodiArtists>
    func getArtistId(_ name: String) -> Observable<Int>
    func playArtist(_ artistid: Int, shuffle: Bool) -> Observable<Bool>

    func getGenres() -> Observable<KodiGenres>
    func playGenre(_ genreid: Int, shuffle: Bool) -> Observable<Bool>
}
