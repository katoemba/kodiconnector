//
//  KodiControl.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import ConnectorProtocol
import RxSwift

public class KodiControl: ControlProtocol {
    private var kodi: KodiProtocol

    public init(kodi: KodiProtocol) {
        self.kodi = kodi
    }
    
    public func play() -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.play())
    }
    
    public func play(index: Int) -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.goto(index))
    }
    
    public func pause() -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.pause())
    }
    
    public func stop() -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.stop())
    }
    
    private func requestWithStatus(controlObservable: Observable<Bool>) -> Observable<PlayerStatus> {
        let kodi = self.kodi
        return controlObservable
            .filter({ (success) -> Bool in
                success == true
            })
            .flatMap({ (_) -> Observable<PlayerStatus> in
                KodiStatus(kodi: kodi)
                    .getStatus()
            })
    }
    
    public func togglePlayPause() -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.togglePlayPause())
    }
    
    public func skip() -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.skip())
    }
    
    public func back() -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.back())
    }
    
    public func setRandom(_ randomMode: RandomMode) -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.setShuffle(randomMode == .On))
    }
    
    public func toggleRandom() -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.toggleShuffle())
    }
    
    public func shufflePlayqueue() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func setRepeat(_ repeatMode: RepeatMode) -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.setRepeat(repeatMode == .All ? "all" : (repeatMode == .Single ? "one" : "off")))
    }
    
    public func toggleRepeat() -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.cycleRepeat())
    }
    
    public func setConsume(_ consumeMode: ConsumeMode) {
    }
    
    public func toggleConsume() {
    }
    
    public func setVolume(_ volume: Float) {
        // Don't use a dispose bag, as that will immediately release the observable.
        _ = kodi.setVolume(volume)
            .subscribe()
    }
    
    public func setSeek(seconds: UInt32) {
        // Don't use a dispose bag, as that will immediately release the observable.
        _ = kodi.seek(seconds)
            .subscribe()
    }
    
    public func setSeek(percentage: Float) {
        // Don't use a dispose bag, as that will immediately release the observable.
        _ = kodi.seek(percentage)
            .subscribe()
    }
    
    public func add(_ song: Song, addDetails: AddDetails) -> Observable<(Song, AddResponse)> {
        guard let songId = Int(song.id) else {
            return Observable.empty()
        }
        
        switch addDetails.addMode {
        case .replace:
            return requestWithStatus(controlObservable: kodi.playSong(songId))
                .map({ (playerStatus) -> (Song, AddResponse) in
                    (song, AddResponse(addDetails, playerStatus))
                })
        case .addAtEnd:
            return requestWithStatus(controlObservable: kodi.addSongs([songId]))
                .map({ (playerStatus) -> (Song, AddResponse) in
                    (song, AddResponse(addDetails, playerStatus))
                })
        case .addNext:
            return KodiStatus(kodi: kodi).getStatus()
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap { (position) -> Observable<PlayerStatus> in
                    self.requestWithStatus(controlObservable: self.kodi.insertSongs([songId], at: position))
                }
                .map({ (playerStatus) -> (Song, AddResponse) in
                    (song, AddResponse(addDetails, playerStatus))
                })
        case .addNextAndPlay:
            return KodiStatus(kodi: kodi).getStatus()
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap { (position) -> Observable<PlayerStatus> in
                    self.requestWithStatus(controlObservable: self.kodi.insertSongs([songId], at: position))
                }
                .flatMap({ (playerStatus) -> Observable<PlayerStatus> in
                    return self.skip()
                })
                .map({ (playerStatus) -> (Song, AddResponse) in
                    (song, AddResponse(addDetails, playerStatus))
                })
        }
    }
    
    public func add(_ songs: [Song], addDetails: AddDetails) -> Observable<([Song], AddResponse)> {
        let songIds = songs.map { (song) -> Int in
            Int(song.id)!
        }
        
        switch addDetails.addMode {
        case .replace:
            return kodi.clearPlayqueue(0)
                .flatMap({ (_) -> Observable<PlayerStatus> in
                    KodiStatus(kodi: self.kodi).getStatus()
                })
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap { (position) -> Observable<PlayerStatus> in
                    self.requestWithStatus(controlObservable: self.kodi.insertSongs(songIds, at: position))
                }
                .flatMap({ (playerStatus) -> Observable<Bool> in
                    return self.kodi.goto(Int(addDetails.startWithSong))
                })
                .flatMap({ (_) -> Observable<PlayerStatus> in
                    KodiStatus(kodi: self.kodi).getStatus()
                })
                .map({ (playerStatus) -> ([Song], AddResponse) in
                    (songs, AddResponse(addDetails, playerStatus))
                })
        case .addAtEnd:
            return requestWithStatus(controlObservable: kodi.addSongs(songIds))
                .map({ (playerStatus) -> ([Song], AddResponse) in
                    (songs, AddResponse(addDetails, playerStatus))
                })
        case .addNext:
            return KodiStatus(kodi: kodi).getStatus()
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap { (position) -> Observable<PlayerStatus> in
                    self.requestWithStatus(controlObservable: self.kodi.insertSongs(songIds, at: position))
                }
                .map({ (playerStatus) -> ([Song], AddResponse) in
                    (songs, AddResponse(addDetails, playerStatus))
                })
        case .addNextAndPlay:
            return KodiStatus(kodi: kodi).getStatus()
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap { (position) -> Observable<Int> in
                    return self.kodi.insertSongs(songIds, at: position)
                        .map({ (_) -> Int in
                            position
                        })
                }
                .flatMap({ (position) -> Observable<PlayerStatus> in
                    return self.play(index: position)
                })
                .map({ (playerStatus) -> ([Song], AddResponse) in
                    (songs, AddResponse(addDetails, playerStatus))
                })
        }
    }
    
    public func addToPlaylist(_ song: Song, playlist: Playlist) -> Observable<(Song, Playlist)> {
        return Observable.empty()
    }
    
    public func add(_ album: Album, addDetails: AddDetails) -> Observable<(Album, AddResponse)> {
        guard let albumId = Int(album.id) else {
            return Observable.empty()
        }
        
        switch addDetails.addMode {
        case .replace:
            return requestWithStatus(controlObservable: kodi.playAlbum(albumId, shuffle: addDetails.shuffle))
                .map({ (playerStatus) -> (Album, AddResponse) in
                    (album, AddResponse(addDetails, playerStatus))
                })
        case .addAtEnd:
            return requestWithStatus(controlObservable: kodi.addAlbum(albumId))
                .map({ (playerStatus) -> (Album, AddResponse) in
                    (album, AddResponse(addDetails, playerStatus))
                })
        case .addNext:
            return KodiStatus(kodi: kodi).getStatus()
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap { (position) -> Observable<PlayerStatus> in
                    self.requestWithStatus(controlObservable: self.kodi.insertAlbum(albumId, at: position))
                }
                .map({ (playerStatus) -> (Album, AddResponse) in
                    (album, AddResponse(addDetails, playerStatus))
                })
        case .addNextAndPlay:
            return KodiStatus(kodi: kodi).getStatus()
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap { (position) -> Observable<Int> in
                    return self.kodi.insertAlbum(albumId, at: position)
                        .map({ (_) -> Int in
                            position
                        })
                }
                .flatMap({ (position) -> Observable<PlayerStatus> in
                    return self.play(index: position)
                })
                .map({ (playerStatus) -> (Album, AddResponse) in
                    (album, AddResponse(addDetails, playerStatus))
                })
        }
    }
    
    public func addToPlaylist(_ album: Album, playlist: Playlist) -> Observable<(Album, Playlist)> {
        return Observable.empty()
    }
    
    public func add(_ artist: Artist, addDetails: AddDetails) -> Observable<(Artist, AddResponse)> {
        guard let artistId = Int(artist.id) else {
            return Observable.empty()
        }
        
        return requestWithStatus(controlObservable: kodi.playArtist(artistId, shuffle: addDetails.shuffle))
            .map({ (playerStatus) -> (Artist, AddResponse) in
                (artist, AddResponse(addDetails, playerStatus))
            })
    }
    
    public func add(_ playlist: Playlist, addDetails: AddDetails) -> Observable<(Playlist, AddResponse)> {
        return Observable.empty()
    }
    
    public func add(_ genre: Genre, addDetails: AddDetails) -> Observable<(Genre, AddResponse)> {
        guard let genreId = Int(genre.id) else {
            return Observable.empty()
        }
        
        return requestWithStatus(controlObservable: kodi.playGenre(genreId, shuffle: addDetails.shuffle))
            .map({ (playerStatus) -> (Genre, AddResponse) in
                (genre, AddResponse(addDetails, playerStatus))
            })
    }
    
    public func add(_ folder: Folder, addDetails: AddDetails) -> Observable<(Folder, AddResponse)> {
        return Observable.empty()
    }
    
    public func addRecursive(_ folder: Folder, addDetails: AddDetails) -> Observable<(Folder, AddResponse)> {
        return Observable.empty()
    }
    
    public func moveSong(from: Int, to: Int) {
    }
    
    public func deleteSong(_ at: Int) {
    }
    
    public func moveSong(playlist: Playlist, from: Int, to: Int) {
    }
    
    public func deleteSong(playlist: Playlist, at: Int) {
    }
    
    public func savePlaylist(_ name: String) {
    }
    
    public func clearPlayqueue() {
        let kodi = self.kodi
        
        _ = kodi.getPlayerProperties()
            .map({ (playerProperties) -> Int in
                playerProperties.playlistid
            })
            .flatMap({ (playlistId) -> Observable<Bool> in
                kodi.clearPlayqueue(playlistId)
            })
            .subscribe()
    }
    
    public func playStation(_ station: Station) {
    }
    
    public func setOutput(_ output: Output, enabled: Bool) {
    }
    
    public func toggleOutput(_ output: Output) {
    }
    
}
