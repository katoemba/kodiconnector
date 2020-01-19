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
import RxSwiftExt

public class KodiControl: ControlProtocol {
    private var kodi: KodiProtocol
    private var kodiStatus: KodiStatus

    public init(kodi: KodiProtocol, kodiStatus: KodiStatus) {
        self.kodi = kodi
        self.kodiStatus = kodiStatus
    }
    
    public func play() -> Observable<PlayerStatus> {
        return requestWithStatus(stream: .audio, controlObservable: kodi.play())
    }
    
    public func play(index: Int) -> Observable<PlayerStatus> {
        return requestWithStatus(stream: .audio, controlObservable: kodi.goto(index))
    }
    
    public func pause() -> Observable<PlayerStatus> {
        if kodi.stream == .audio {
            return requestWithStatus(controlObservable: kodi.pause())
        }
        else {
            return stop()
        }
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
    
    private func requestWithStatus(stream: KodiStream, controlObservable: Observable<Bool>) -> Observable<PlayerStatus> {
        let kodi = self.kodi
        return kodi.activateStream(stream)
            .flatMapFirst { (_) -> Observable<Bool> in
                controlObservable
            }
            .filter({ (success) -> Bool in
                success == true
            })
            .flatMap({ (_) -> Observable<PlayerStatus> in
                KodiStatus(kodi: kodi)
                    .getStatus()
            })
    }
    
    public func togglePlayPause() -> Observable<PlayerStatus> {
        if kodi.stream == .audio {
            return requestWithStatus(stream: .audio, controlObservable: kodi.togglePlayPause())
        }
        else {
            return requestWithStatus(controlObservable: kodi.stop())
        }
    }
    
    public func skip() -> Observable<PlayerStatus> {
        return requestWithStatus(stream: .audio, controlObservable: kodi.skip())
    }
    
    public func back() -> Observable<PlayerStatus> {
        return requestWithStatus(stream: .audio, controlObservable: kodi.back())
    }
    
    public func setRandom(_ randomMode: RandomMode) -> Observable<PlayerStatus> {
        return requestWithStatus(stream: .audio, controlObservable: kodi.setShuffle(randomMode == .On))
    }
    
    public func toggleRandom() -> Observable<PlayerStatus> {
        return requestWithStatus(stream: .audio, controlObservable: kodi.toggleShuffle())
    }
    
    public func shufflePlayqueue() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func setRepeat(_ repeatMode: RepeatMode) -> Observable<PlayerStatus> {
        return requestWithStatus(stream: .audio, controlObservable: kodi.setRepeat(repeatMode == .All ? "all" : (repeatMode == .Single ? "one" : "off")))
    }
    
    public func toggleRepeat() -> Observable<PlayerStatus> {
        return requestWithStatus(stream: .audio, controlObservable: kodi.cycleRepeat())
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
        // Seek is only possible on the audio stream, not for radio
        if kodi.stream == .audio {
            // Don't use a dispose bag, as that will immediately release the observable.
            _ = kodi.seek(seconds)
                .subscribe()
        }
    }
    
    public func setSeek(percentage: Float) {
        // Seek is only possible on the audio stream, not for radio
        if kodi.stream == .audio {
            // Don't use a dispose bag, as that will immediately release the observable.
            _ = kodi.seek(percentage)
                .subscribe()
        }
    }
    
    public func add(_ song: Song, addDetails: AddDetails) -> Observable<(Song, AddResponse)> {
        guard let songId = Int(song.id) else {
            return Observable.empty()
        }
        
        switch addDetails.addMode {
        case .replace:
            return requestWithStatus(stream: .audio, controlObservable: kodi.playSong(songId))
                .map({ (playerStatus) -> (Song, AddResponse) in
                    (song, AddResponse(addDetails, playerStatus))
                })
        case .addAtEnd:
            return requestWithStatus(stream: .audio, controlObservable: kodi.addSongs([songId]))
                .map({ (playerStatus) -> (Song, AddResponse) in
                    (song, AddResponse(addDetails, playerStatus))
                })
        case .addNext:
            return KodiStatus(kodi: kodi).getStatus()
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap { (position) -> Observable<PlayerStatus> in
                    self.requestWithStatus(stream: .audio, controlObservable: self.kodi.insertSongs([songId], at: position))
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
                    self.requestWithStatus(stream: .audio, controlObservable: self.kodi.insertSongs([songId], at: position))
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
        var songIds = songs.map { (song) -> Int in
            Int(song.id)!
        }
        if addDetails.shuffle {
            songIds.shuffle()
        }
        
        switch addDetails.addMode {
        case .replace:
            return kodi.clearPlaylist(0)
                .flatMap { (_) -> Observable<PlayerStatus> in
                    self.requestWithStatus(stream: .audio, controlObservable: self.kodi.addSongs(songIds))
                }
                .flatMap({ (_) -> Observable<Bool> in
                    self.kodi.startPlaylist(0, at: Int(addDetails.startWithSong))
                })
                .flatMap({ (_) -> Observable<PlayerStatus> in
                    KodiStatus(kodi: self.kodi).getStatus()
                })
                .map({ (playerStatus) -> ([Song], AddResponse) in
                    (songs, AddResponse(addDetails, playerStatus))
                })
        case .addAtEnd:
            return requestWithStatus(stream: .audio, controlObservable: kodi.addSongs(songIds))
                .map({ (playerStatus) -> ([Song], AddResponse) in
                    (songs, AddResponse(addDetails, playerStatus))
                })
        case .addNext:
            return KodiStatus(kodi: kodi).getStatus()
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap { (position) -> Observable<PlayerStatus> in
                    self.requestWithStatus(stream: .audio, controlObservable: self.kodi.insertSongs(songIds, at: position))
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
            return kodi.activateStream(.audio)
                .flatMapFirst { (_) -> Observable<Bool> in
                    self.kodi.playAlbum(albumId, shuffle: addDetails.shuffle)
                }
                .flatMap { (_) -> Observable<Bool> in
                    self.kodi.startPlaylist(0, at: 0)
                }
                .flatMap({ (_) -> Observable<PlayerStatus> in
                    KodiStatus(kodi: self.kodi).getStatus()
                })
                .map({ (playerStatus) -> (Album, AddResponse) in
                    (album, AddResponse(addDetails, playerStatus))
                })
        case .addAtEnd:
            return requestWithStatus(stream: .audio, controlObservable: kodi.addAlbum(albumId))
                .map({ (playerStatus) -> (Album, AddResponse) in
                    (album, AddResponse(addDetails, playerStatus))
                })
        case .addNext:
            return KodiStatus(kodi: kodi).getStatus()
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap { (position) -> Observable<PlayerStatus> in
                    self.requestWithStatus(stream: .audio, controlObservable: self.kodi.insertAlbum(albumId, at: position))
                }
                .map({ (playerStatus) -> (Album, AddResponse) in
                    (album, AddResponse(addDetails, playerStatus))
                })
        case .addNextAndPlay:
            return KodiStatus(kodi: kodi).getStatus()
                .map { (playerStatus) -> Int in
                    playerStatus.playqueue.songIndex + 1
                }
                .flatMap({ [weak self] (position) -> Observable<Int> in
                    guard let weakSelf = self else { return Observable.empty() }
                    
                    return weakSelf.kodi.activateStream(.audio)
                        .map { (_) -> Int in
                            position
                        }
                })
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
        
        return requestWithStatus(stream: .audio, controlObservable: kodi.playArtist(artistId, shuffle: addDetails.shuffle))
            .map({ (playerStatus) -> (Artist, AddResponse) in
                (artist, AddResponse(addDetails, playerStatus))
            })
    }
    
    public func add(_ playlist: Playlist, addDetails: AddDetails) -> Observable<(Playlist, AddResponse)> {
        return kodi.getDirectory(playlist.id)
            .map({ (kodiFiles) -> [Song] in
                kodiFiles.files
                    .compactMap({ (kodiFile) -> Song? in
                        if case let .song(song)? = kodiFile.folderContent(kodiAddress: self.kodi.kodiAddress) {
                            return song
                        }
                        return nil
                    })
            })
            .flatMap { (songs) -> Observable<(Playlist, AddResponse)> in
                return self.add(songs, addDetails: addDetails)
                    .map({ (_, addResponse) -> (Playlist, AddResponse) in
                        (playlist, addResponse)
                    })
        }
    }
    
    public func add(_ genre: Genre, addDetails: AddDetails) -> Observable<(Genre, AddResponse)> {
        guard let genreId = Int(genre.id) else {
            return Observable.empty()
        }
        
        return requestWithStatus(stream: .audio, controlObservable: kodi.playGenre(genreId, shuffle: addDetails.shuffle))
            .map({ (playerStatus) -> (Genre, AddResponse) in
                (genre, AddResponse(addDetails, playerStatus))
            })
    }
    
    public func add(_ folder: Folder, addDetails: AddDetails) -> Observable<(Folder, AddResponse)> {
        return kodi.getDirectory(folder.path)
            .map({ (kodiFiles) -> [Song] in
                kodiFiles.files.sorted()
                    .compactMap({ (kodiFile) -> Song? in
                        if case let .song(song)? = kodiFile.folderContent(kodiAddress: self.kodi.kodiAddress) {
                            return song
                        }
                        return nil
                    })
            })
            .flatMap { (songs) -> Observable<(Folder, AddResponse)> in
                return self.add(songs, addDetails: addDetails)
                    .map({ (_, addResponse) -> (Folder, AddResponse) in
                        (folder, addResponse)
                    })
        }
    }
    
    public func addRecursive(_ folder: Folder, addDetails: AddDetails) -> Observable<(Folder, AddResponse)> {
        // Add recursive is not supported for kodi.
        return add(folder, addDetails: addDetails)
    }
    
    public func moveSong(from: Int, to: Int) {
        kodiStatus.playqueueChanged()
        _ = kodi.getPlaylist(0, start: from, end: from+1)
            .flatMap({ (kodiSongs) -> Observable<Int> in
                guard kodiSongs.count > 0 else { return Observable.empty() }
                return Observable.just(kodiSongs[0].uniqueId)
            })
            .flatMap({ (songId) -> Observable<Int> in
                self.kodi.removeFromPlaylist(0, position: from)
                    .map({ (_) -> Int in
                        songId
                    })
            })
            .flatMap({ (songId) -> Observable<Bool> in
                self.kodi.insertSongs([songId], at: to)
            })
            .subscribe()
    }
    
    public func deleteSong(_ at: Int) {
        _ = kodi.removeFromPlaylist(0, position: at)
            .subscribe()
    }
    
    public func moveSong(playlist: Playlist, from: Int, to: Int) {
        guard let playlistId = Int(playlist.id) else { return }

        _ = kodi.swapItemsInPlaylist(playlistId, position1: from, position2: to)
            .subscribe()
    }
    
    public func deleteSong(playlist: Playlist, at: Int) {
        guard let playlistId = Int(playlist.id) else { return }
        
        _ = kodi.removeFromPlaylist(playlistId, position: at)
            .subscribe()
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
                kodi.clearPlaylist(playlistId)
            })
            .subscribe()
    }
    
    public func playStation(_ station: Station) {
        print("Playing station \(station.url)")
        _ = kodi.activateStream(.video)
            .delay(RxTimeInterval.milliseconds(1000), scheduler: MainScheduler.instance)
            .flatMapFirst({ (_) -> Observable<Bool> in
                self.kodi.play(station.url)
            })
            .subscribe(onNext: { (_) in
                self.kodiStatus.lastStationUrl = station.url
            })
    }
    
    public func setOutput(_ output: Output, enabled: Bool) {
    }
    
    public func toggleOutput(_ output: Output) {
    }
    
}
