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
    public func play() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func play(index: Int) -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func pause() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func stop() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func togglePlayPause() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func skip() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func back() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func setRandom(randomMode: RandomMode) -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func toggleRandom() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func shufflePlayqueue() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func setRepeat(repeatMode: RepeatMode) -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func toggleRepeat() -> Observable<PlayerStatus> {
        return Observable.empty()
    }
    
    public func setConsume(consumeMode: ConsumeMode) {
    }
    
    public func toggleConsume() {
    }
    
    public func setVolume(volume: Float) {
    }
    
    public func setSeek(seconds: UInt32) {
    }
    
    public func setSeek(percentage: Float) {
    }
    
    public func addSong(_ song: Song, addMode: AddMode) -> Observable<(Song, AddMode, PlayerStatus)> {
        return Observable.empty()
    }
    
    public func addSongs(_ songs: [Song], addMode: AddMode) -> Observable<([Song], AddMode, PlayerStatus)> {
        return Observable.empty()
    }
    
    public func addSongToPlaylist(_ song: Song, playlist: Playlist) -> Observable<(Song, Playlist)> {
        return Observable.empty()
    }
    
    public func addAlbum(_ album: Album, addMode: AddMode, shuffle: Bool, startWithSong: UInt32) -> Observable<(Album, Song, AddMode, Bool, PlayerStatus)> {
        return Observable.empty()
    }
    
    public func addAlbumToPlaylist(_ album: Album, playlist: Playlist) -> Observable<(Album, Playlist)> {
        return Observable.empty()
    }
    
    public func addArtist(_ artist: Artist, addMode: AddMode, shuffle: Bool) -> Observable<(Artist, AddMode, Bool, PlayerStatus)> {
        return Observable.empty()
    }
    
    public func addPlaylist(_ playlist: Playlist, shuffle: Bool, startWithSong: UInt32) -> Observable<(Playlist, Song, Bool, PlayerStatus)> {
        return Observable.empty()
    }
    
    public func addGenre(_ genre: String, addMode: AddMode, shuffle: Bool) {
    }
    
    public func addFolder(_ folder: Folder, addMode: AddMode, shuffle: Bool, startWithSong: UInt32) -> Observable<(Folder, Song, AddMode, Bool, PlayerStatus)> {
        return Observable.empty()
    }
    
    public func addRecursiveFolder(_ folder: Folder, addMode: AddMode, shuffle: Bool) -> Observable<(Folder, AddMode, Bool, PlayerStatus)> {
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
