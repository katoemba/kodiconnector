//
//  KodiSongBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ConnectorProtocol

public class KodiSongBrowseViewModel: SongBrowseViewModel {
    
    private var loadProgress = BehaviorRelay<LoadProgress>(value: .notStarted)
    public var loadProgressObservable: Observable<LoadProgress> {
        return loadProgress.asObservable()
    }

    private var songsSubject = PublishSubject<[Song]>()
    public var songsObservable: Observable<[Song]> {
        return songsSubject.asObservable()
    }
    public var songsWithSubfilterObservable: Observable<[Song]> {
        return songsObservable
            .map({ [weak self] (songs) -> [Song] in
                guard let weakSelf = self else { return songs }
                
                if let subFilter = weakSelf.subFilter, case let .artist(artist) = subFilter {
                    var filteredSongs = [Song]()
                    for song in songs {
                        if artist.type == .artist || artist.type == .albumArtist {
                            if song.albumartist.lowercased().contains(artist.name.lowercased()) || song.artist.lowercased().contains(artist.name.lowercased()) {
                                filteredSongs.append(song)
                            }
                        }
                        else if artist.type == .composer {
                            if song.composer.lowercased().contains(artist.name.lowercased()) {
                                filteredSongs.append(song)
                            }
                        }
                        else if artist.type == .performer {
                            if song.performer.lowercased().contains(artist.name.lowercased()) {
                                filteredSongs.append(song)
                            }
                        }
                    }
                    return filteredSongs
                }
                return songs
            })
    }

    private var bag = DisposeBag()
    private var kodi: KodiProtocol
    public private(set) var filter: BrowseFilter?
    public private(set) var subFilter: BrowseFilter?
    private var songs: [Song]

    public required init(kodi: KodiProtocol, songs: [Song] = [], filter: BrowseFilter? = nil, subFilter: BrowseFilter? = nil) {
        self.kodi = kodi
        self.songs = songs
        self.filter = filter
        self.subFilter = subFilter
    }

    public func load() {
        if songs.count > 0 {
            loadProgress.accept(.allDataLoaded)
            bag = DisposeBag()
            songsSubject.onNext(songs)
        }
        else if filter != nil {
            reload(filter: filter!)
        }
        else {
            fatalError("MPDSongBrowseViewModel: load without filters not allowed")
        }
    }
    
    private func reload(filter: BrowseFilter) {
        loadProgress.accept(.loading)
        
        // Get rid of old disposables
        bag = DisposeBag()
        
        // Clear the contents
        self.songsSubject.onNext([])
        
        let kodi = self.kodi
        let songsSubject = self.songsSubject
        
        var songsObservable : Observable<[Song]>
        switch filter {
        case let .playlist(playlist):
            songsObservable = kodi.getDirectory(playlist.id)
                .map { [weak self] (kodiFiles) -> [Song] in
                    guard let weakSelf = self else { return [] }
                    guard let files = kodiFiles.files else { return [] }

                    return files.compactMap({ (kodiFile) -> Song? in
                        let folderContent = kodiFile.folderContent(kodiAddress: weakSelf.kodi.kodiAddress)
                        
                        if case let .song(song)? = folderContent {
                            return song
                        }
                        return nil
                    })
            }
        case let .album(album):
            guard let albumId = Int(album.id) else {
                songsObservable = Observable.empty()
                break
            }
            
            songsObservable = kodi.getSongsOnAlbum(albumId)
                .map({ [weak self] (kodiSongs) -> [Song] in
                    guard let weakSelf = self else { return [] }

                    return kodiSongs.map({ (kodiSong) -> Song in
                        kodiSong.song(kodiAddress: weakSelf.kodi.kodiAddress)
                    })
                })
                .map({ (songs) -> [Song] in
                    // If songs have track numbers, sort them by track number. Otherwise pass untouched.
                    if songs.count > 0, songs[0].track > 0 {
                        return songs.sorted(by: { (lsong, rsong) -> Bool in
                            lsong.track < rsong.track
                        })
                    }
                    return songs
                })
                .observeOn(MainScheduler.instance)
                .share(replay: 1)
        case let .random(count):
            // Getting all the songs is not the best approach, but adding a batch of songs (like 100) is even slower.
            songsObservable = kodi.allSongIds()
                .map({ (songIds) -> [Int] in
                    var randomSongIds = [Int]()
                    for _ in 0..<count {
                        randomSongIds.append(songIds[Int.random(in: 0 ..< songIds.count)])
                    }
                    return randomSongIds
                })
                .map({ (songIds) -> [Song] in
                    songIds.map { (songId) -> Song in
                        Song(id: "\(songId)", source: .Local, location: "", title: "", album: "", artist: "", albumartist: "", composer: "", year: 0, genre: [], length: 0, quality: .init())
                    }
                })
            break
        default:
            fatalError("MPDSongBrowseViewModel: load without filters not allowed")
        }

        songsObservable
            .subscribe(onNext: { (songs) in
                songsSubject.onNext(songs)
            })
            .disposed(by: bag)
        
        songsObservable
            .filter({ (itemsFound) -> Bool in
                itemsFound.count > 0
            })
            .map { (_) -> LoadProgress in
                .allDataLoaded
            }
            .bind(to: loadProgress)
            .disposed(by: bag)
        
        songsObservable
            .filter({ (itemsFound) -> Bool in
                itemsFound.count == 0
            })
            .map { (_) -> LoadProgress in
                .noDataFound
            }
            .bind(to: loadProgress)
            .disposed(by: bag)
    }
    
    public func extend() {
    }
    
    public func removeSong(at: Int) {
        Observable.just(at)
            .withLatestFrom(songsSubject) { (at, songs) in
                (at, songs)
            }
            .map({ (arg) -> [Song] in
                let (at, songs) = arg
                var newSongs = songs
                newSongs.remove(at: at)
                return newSongs
            })
            .subscribe(onNext: { [weak self] (songs) in
                guard let weakSelf = self else { return }
                weakSelf.songsSubject.onNext(songs)
            })
            .disposed(by: bag)
    }
}
