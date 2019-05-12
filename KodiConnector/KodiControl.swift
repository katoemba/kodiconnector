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
import RxCocoa

public class KodiControl: ControlProtocol {
    private var kodi: KodiProtocol

    public init(kodi: KodiProtocol) {
        self.kodi = kodi
    }
    
    public func play() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func play(index: Int) -> Observable<PlayerStatus> {
        return requestWithStatus(controlObservable: kodi.goto(index))
    }
    
    public func pause() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func stop() -> Observable<PlayerStatus> {
        return Observable.empty()
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
        return Observable.empty()
    }
    
    public func toggleRandom() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func shufflePlayqueue() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func setRepeat(_ repeatMode: RepeatMode) -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func toggleRepeat() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func setConsume(_ consumeMode: ConsumeMode) {
    }
    
    public func toggleConsume() {
    }
    
    public func setVolume(_ volume: Float) {
    }
    
    public func setSeek(seconds: UInt32) {
    }
    
    public func setSeek(percentage: Float) {
    }
    
    public func add(_ song: Song, addDetails: AddDetails) -> Observable<(Song, AddResponse)> {
        return Observable.empty()
    }
    
    public func add(_ songs: [Song], addDetails: AddDetails) -> Observable<([Song], AddResponse)> {
        return Observable.empty()
    }
    
    public func addToPlaylist(_ song: Song, playlist: Playlist) -> Observable<(Song, Playlist)> {
        return Observable.empty()
    }
    
    public func add(_ album: Album, addDetails: AddDetails) -> Observable<(Album, AddResponse)> {
        return requestWithStatus(controlObservable: kodi.playAlbum(album, shuffle: addDetails.shuffle))
            .map({ (playerStatus) -> (Album, AddResponse) in
                (album, AddResponse(addDetails, playerStatus))
            })
    }
    
    public func addToPlaylist(_ album: Album, playlist: Playlist) -> Observable<(Album, Playlist)> {
        return Observable.empty()
    }
    
    public func add(_ artist: Artist, addDetails: AddDetails) -> Observable<(Artist, AddResponse)> {
        return Observable.empty()
    }
    
    public func add(_ playlist: Playlist, addDetails: AddDetails) -> Observable<(Playlist, AddResponse)> {
        return Observable.empty()
    }
    
    public func add(_ genre: Genre, addDetails: AddDetails) -> Observable<(Genre, AddResponse)> {
        return Observable.empty()
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
    }
    
    public func playStation(_ station: Station) {
    }
    
    public func setOutput(_ output: Output, enabled: Bool) {
    }
    
    public func toggleOutput(_ output: Output) {
    }
    
}
