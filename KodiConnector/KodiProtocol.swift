//
//  KodiProtocol.swift
//  KodiConnector_iOS
//
//  Created by Berrie Kremers on 12/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import ConnectorProtocol

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

public struct KodiPlayerProperties {
    var position = -1
    var elapsedTime = 0
    var totalTime = 0
    var canSeek = false
    var type = ""
    var shuffled = false
    var `repeat` = "off"
    var speed = 0
    var playlistId = -1
}

public protocol KodiProtocol {
    func pong() -> Observable<Bool>
    func getKodiVersion() -> Observable<String>
    func getApiVersion() -> Observable<String>
    func getActivePlayers() -> Observable<(Int, Bool)>
    func getAudioPlaylist() -> Observable<Int>
    func getPlayerProperties() -> Observable<KodiPlayerProperties>
    func getCurrentSong() -> Observable<Song>
    func getPlayQueue(start: Int, end: Int) -> Observable<[Song]>

    func togglePlayPause() -> Observable<Bool>
    func back() -> Observable<Bool>
    func skip() -> Observable<Bool>
    func goto(_ index: Int) -> Observable<Bool>
    func clearPlayqueue(_ playlistId: Int) -> Observable<Bool>
    func playAlbum(_ album: Album, shuffle: Bool) -> Observable<Bool>

    func getRecentAlbums(count: Int) -> Observable<[Album]>
    func getAlbums(start: Int, end: Int) -> Observable<[Album]>
    func getSongsOnAlbum(_ album: Album) -> Observable<[Song]>
    func getSongsInPlaylist(_ playlist: Playlist) -> Observable<[Song]>
}
