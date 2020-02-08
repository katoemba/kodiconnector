//
//  KodiProtocol.swift
//  KodiConnector_iOS
//
//  Created by Berrie Kremers on 12/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift

public enum KodiStream: Int {
    case audio = 0
    case video = 1
}

public struct KodiAddress {
    var ip: String
    var port: Int
    var websocketPort: Int
    
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
    var displayartist: String?
    var album: String
    var albumartist: [String]
    var duration: Int
    var year: Int
    var track: Int
    var genre: [String]
    var thumbnail: String
    var albumid: Int
    var artistid: [Int]?
    var albumartistid: [Int]?
    
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

public struct KodiSource: Decodable {
    var file: String
    var label: String
}
public struct KodiSources: Decodable {
    var sources: [KodiSource]
    var limits: Limits
}

public struct KodiFile: Decodable {
    var file: String
    var filetype: String
    var label: String
    var type: String
    var thumbnail: String
    var id: Int?
    var displayartist: String?
    var albumartist: [String]?
    var album: String?
    var duration: Int?
    var year: Int?
    var genre: [String]?
    var track: Int?
}
extension KodiFile: Comparable {
    public static func < (lhs: KodiFile, rhs: KodiFile) -> Bool {
        // First folder
        if lhs.filetype == "directory" {
            if rhs.filetype == "directory" {
                return lhs.label < rhs.label
            }
            return true
        }
        if rhs.filetype == "directory" {
            return false
        }
        
        // Then song by track then label
        if (lhs.track ?? 0) == (rhs.track ?? 0) {
            return lhs.label < rhs.label
        }
        else {
            return (lhs.track ?? 0) < (rhs.track ?? 0)
        }
    }
}
public struct KodiFiles: Decodable {
    var files: [KodiFile]?
    var limits: Limits
}

public protocol KodiProtocol {
    var kodiAddress: KodiAddress { get }
    var stream: KodiStream { get }
    
    func getKodiVersion() -> Observable<String>
    func getApiVersion() -> Observable<String>
    func getApplicationProperties() -> Observable<(String, String, Int)>
    
    func ping() -> Observable<Bool>
    func getActivePlayers() -> Observable<(Int, Bool)>
    func scan() -> Observable<Bool>
    func clean() -> Observable<Bool>
    func activateStream(_ stream: KodiStream) -> Observable<Bool>
    func activateStream(_ streamId: Int) -> Observable<Bool>

    func getAudioPlaylist() -> Observable<Int>
    func getPlayerProperties() -> Observable<KodiPlayerProperties>
    func parseNotification(_ notification: Data) -> Notification?
    
    func getPropertiesForPlaylist(_ playlistId: Int) -> Observable<(Int, String)>
    func getPlaylist(_ playlistId: Int, start: Int, end: Int) -> Observable<[KodiSong]>
    func clearPlaylist(_ playlistId: Int) -> Observable<Bool>
    func startPlaylist(_ playlistId: Int, at: Int) -> Observable<Bool>
    func removeFromPlaylist(_ playlistId: Int, position: Int) -> Observable<Bool>
    func swapItemsInPlaylist(_ playlistId: Int, position1: Int, position2: Int) -> Observable<Bool>
    func addPlaylist(_ playlist: String, shuffle: Bool) -> Observable<Bool>
    func playPlaylist(_ playlist: String, shuffle: Bool) -> Observable<Bool>
    
    func play() -> Observable<Bool>
    func pause() -> Observable<Bool>
    func stop() -> Observable<Bool>
    func togglePlayPause() -> Observable<Bool>
    func back() -> Observable<Bool>
    func skip() -> Observable<Bool>
    func goto(_ index: Int) -> Observable<Bool>
    func setShuffle(_ on: Bool) -> Observable<Bool>
    func toggleShuffle() -> Observable<Bool>
    func setRepeat(_ mode: String) -> Observable<Bool>
    func cycleRepeat() -> Observable<Bool>
    func setVolume(_ volume: Float) -> Observable<Bool>
    func seek(_ seconds: UInt32) -> Observable<Bool>
    func seek(_ percentage: Float) -> Observable<Bool>
    func play(_ url: String) -> Observable<Bool>
    
    func getCurrentSong() -> Observable<KodiSong?>
    func getSong(_ songid: Int) -> Observable<KodiSong>
    func getSongsOnAlbum(_ albumid: Int) -> Observable<[KodiSong]>
    func allSongIds() -> Observable<[Int]>
    func searchSongs(_ search: String, limit: Int) -> Observable<[KodiSong]>
    func playSong(_ songid: Int) -> Observable<Bool>
    func addSongs(_ songids: [Int]) -> Observable<Bool>
    func insertSongs(_ songids: [Int], at: Int) -> Observable<Bool>
    
    func getRecentAlbums(count: Int) -> Observable<KodiAlbums>
    func getAlbums(start: Int, end: Int, sort:  [String: Any]) -> Observable<KodiAlbums>
    func getAlbums(artistid: Int, sort: [String: Any]) -> Observable<KodiAlbums>
    func getAlbums(genreid: Int, sort: [String: Any]) -> Observable<KodiAlbums>
    func getAlbum(_ albumid: Int) -> Observable<KodiAlbum>
    func searchAlbums(_ search: String, limit: Int) -> Observable<[KodiAlbum]>
    func allAlbumIds() -> Observable<[Int]>
    func playAlbum(_ albumid: Int, shuffle: Bool) -> Observable<Bool>
    func addAlbum(_ albumid: Int) -> Observable<Bool>
    func insertAlbum(_ albumid: Int, at: Int) -> Observable<Bool>

    func getArtists(start: Int, end: Int, albumartistsonly: Bool) -> Observable<KodiArtists>
    func getArtistId(_ name: String) -> Observable<Int>
    func getArtist(_ artistid: Int) -> Observable<KodiArtist>
    func searchArtists(_ search: String, limit: Int) -> Observable<[KodiArtist]>
    func playArtist(_ artistid: Int, shuffle: Bool) -> Observable<Bool>

    func getGenres() -> Observable<KodiGenres>
    func playGenre(_ genreid: Int, shuffle: Bool) -> Observable<Bool>
    
    func getSources() -> Observable<KodiSources>
    func getDirectory(_ path: String) -> Observable<KodiFiles>
}
