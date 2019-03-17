//
//  KodiSongBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
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
    
    private var bag = DisposeBag()
    private var kodi: KodiProtocol
    public private(set) var filters: [BrowseFilter]
    private var songs: [Song]

    public required init(kodi: KodiProtocol, songs: [Song] = [], filters: [BrowseFilter] = []) {
        self.kodi = kodi
        self.songs = songs
        self.filters = filters
    }

    public func load() {
        if songs.count > 0 {
            loadProgress.accept(.allDataLoaded)
            bag = DisposeBag()
            songsSubject.onNext(songs)
        }
        else if filters.count > 0 {
            reload(filter: filters[0])
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
            songsObservable = kodi.getSongsInPlaylist(playlist)
                .observeOn(MainScheduler.instance)
                .share(replay: 1)
        case let .album(album):
            songsObservable = kodi.getSongsOnAlbum(album)
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
