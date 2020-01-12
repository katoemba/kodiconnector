//
//  KodiAlbumBrwoseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ConnectorProtocol

public class KodiAlbumBrowseViewModel: AlbumBrowseViewModel {
    private var loadProgress = BehaviorRelay<LoadProgress>(value: .notStarted)
    public var loadProgressObservable: Observable<LoadProgress> {
        return loadProgress.asObservable()
    }
    
    private var albumsSubject = PublishSubject<[Album]>()
    public var albumsObservable: Observable<[Album]> {
        return albumsSubject.asObservable()
    }
    private let extendTriggerSubject = PublishSubject<Int>()
    private let limitsSubject = ReplaySubject<Limits>.create(bufferSize: 1)
    
    public private(set) var filters = [BrowseFilter]()
    public private(set) var sort = SortType.artist
    private let albums: [Album]
    
    
    public var availableSortOptions: [SortType] {
        get {
            if albums.count > 0 {
                return []
            }
            else if filters.count > 0, case .artist(_) = filters[0] {
                return [.title, .year, .yearReverse]
            }
            else if filters.count > 0, case .genre(_) = filters[0] {
                return [.artist, .title, .year, .yearReverse]
            }
            else {
                return [.artist, .title, .year, .yearReverse]
            }
        }
    }
    
    private var kodi: KodiProtocol
    private var bag = DisposeBag()
    
    public init(kodi: KodiProtocol, albums: [Album] = [], filters: [BrowseFilter] = []) {
        self.kodi = kodi
        self.filters = filters
        self.albums = albums
    }
    
    public func load(sort: SortType) {
        self.sort = sort
        load()
    }
    
    public func load(filters: [BrowseFilter]) {
        self.filters = filters
        load()
    }
    
    public func load() {
        if albums.count > 0 {
            loadProgress.accept(.allDataLoaded)
            bag = DisposeBag()
            albumsSubject.onNext(albums)
        }
        else if filters.count > 0 {
            switch filters[0] {
            case let .genre(genre):
                load(genre: genre)
            case let .artist(artist):
                load(artist: artist)
            case let .recent(duration):
                loadRecent(count: duration)
            case let .random(count):
                loadRandom(count: count)
            default:
                fatalError("KodiAlbumBrowseViewModel: unsupported filter type")
            }
        }
        else {
            reload(sort: sort)
        }
    }
    
    private func load(genre: Genre) {
        guard let genreId = Int(genre.id) else {
            return
        }
        
        loadProgress.accept(.loading)
        kodi.getAlbums(genreid: genreId, sort: sort.parameterArray)
            .do() { [weak self] in
                self?.loadProgress.accept(.dataAvailable)
        }
        .map({ [weak self] (kodiAlbums) -> [Album] in
            guard let weakSelf = self else { return [] }
            
            return kodiAlbums.albums.map({ (kodiAlbum) -> Album in
                kodiAlbum.album(kodiAddress: weakSelf.kodi.kodiAddress)
            })
        })
            .subscribe(onNext: { [weak self] (albums) in
                guard let weakSelf = self else { return }
                weakSelf.albumsSubject.onNext(albums)
            })
            .disposed(by: bag)
    }
    
    private func loadRecent(count: Int) {
        loadProgress.accept(.loading)
        kodi.getRecentAlbums(count: count)
            .do() { [weak self] in
                self?.loadProgress.accept(.dataAvailable)
        }
        .map({ [weak self] (kodiAlbums) -> [Album] in
            guard let weakSelf = self else { return [] }
            
            return kodiAlbums.albums.map({ (kodiAlbum) -> Album in
                kodiAlbum.album(kodiAddress: weakSelf.kodi.kodiAddress)
            })
        })
            .subscribe(onNext: { [weak self] (albums) in
                guard let weakSelf = self else { return }
                weakSelf.albumsSubject.onNext(albums)
            })
            .disposed(by: bag)
    }
    
    private func load(artist: Artist) {
        var artistIdObservable: Observable<Int>
        if let artistId = Int(artist.id) {
            artistIdObservable = Observable.just(artistId)
        }
        else {
            artistIdObservable = kodi.getArtistId(artist.name)
        }
        
        loadProgress.accept(.loading)
        let kodi = self.kodi
        artistIdObservable
            .flatMapFirst { [weak self] (artistId) -> Observable<KodiAlbums> in
                guard let weakSelf = self else { return Observable.empty() }
                return kodi.getAlbums(artistid: artistId, sort: weakSelf.sort.parameterArray)
        }
        .do() { [weak self] in
            self?.loadProgress.accept(.dataAvailable)
        }
        .map({ [weak self] (kodiAlbums) -> [Album] in
            guard let weakSelf = self else { return [] }
            
            return kodiAlbums.albums.map({ (kodiAlbum) -> Album in
                kodiAlbum.album(kodiAddress: weakSelf.kodi.kodiAddress)
            })
        })
            .subscribe(onNext: { [weak self] (albums) in
                guard let weakSelf = self else { return }
                weakSelf.albumsSubject.onNext(albums)
            })
            .disposed(by: bag)
    }
    
    private func loadRandom(count: Int) {
        let kodi = self.kodi
        kodi.allAlbumIds()
            .map({ (albumIds) -> [Int] in
                var randomAlbumIds = [Int]()
                for _ in 0..<count {
                    randomAlbumIds.append(albumIds[Int.random(in: 0 ..< albumIds.count)])
                }
                return randomAlbumIds
            })
            .flatMap({ (albumIds) -> Observable<[Album]> in
                Observable.from(albumIds)
                    .flatMap { (albumId) -> Observable<[Album]> in
                        kodi.getAlbum(albumId)
                            .map { (album) -> [Album] in
                                [album.album(kodiAddress: kodi.kodiAddress)]
                        }
                }
                .scan([]) { inputAlbums, newAlbums in
                    inputAlbums + newAlbums
                }
                .filter({ (albums) -> Bool in
                    albums.count == count
                })
            })
            .bind(to: albumsSubject)
            .disposed(by: bag)
    }
    
    private func reload(sort: SortType) {
        let loadNextBatchObservable = extendTriggerSubject
            .withLatestFrom(limitsSubject)
            .filter { (limits) -> Bool in
                limits.end < limits.total
        }
        .distinctUntilChanged({ (left, right) -> Bool in
            left.start == right.start && left.end == right.end
        })
            .share()
        
        loadNextBatchObservable
            .map { (limits) -> LoadProgress in
                .loading
        }
        .bind(to: loadProgress)
        .disposed(by: bag)
        
        let kodi = self.kodi
        let albumFetchObservable = loadNextBatchObservable
            .flatMap { limits -> Observable<KodiAlbums> in
                return kodi.getAlbums(start: limits.end, end: limits.end + 100, sort: SortType.title.parameterArray)
        }
        .share()
        
        albumFetchObservable
            .map { (kodiAlbums) -> Limits in
                kodiAlbums.limits
        }
        .subscribe(onNext: { [weak self] (limits) in
            self?.limitsSubject.onNext(limits)
        })
            .disposed(by: bag)
        
        albumFetchObservable
            .map { (kodiAlbums) -> LoadProgress in
                if kodiAlbums.limits.end >= kodiAlbums.limits.total {
                    return .allDataLoaded
                }
                else {
                    return .dataAvailable
                }
        }
        .bind(to: loadProgress)
        .disposed(by: bag)
        
        albumFetchObservable
            .map({ [weak self] (kodiAlbums) -> [Album] in
                guard let weakSelf = self else { return [] }
                
                return kodiAlbums.albums.map({ (kodiAlbum) -> Album in
                    kodiAlbum.album(kodiAddress: weakSelf.kodi.kodiAddress)
                })
            })
            .scan([]) { inputAlbums, newAlbums in
                inputAlbums + newAlbums
        }
        .subscribe(onNext: { [weak self] (albums) in
            guard let weakSelf = self else { return }
            weakSelf.albumsSubject.onNext(albums)
        })
        .disposed(by: bag)
        
        limitsSubject.onNext(Limits(start: 0, end: 0, total: 1000))
        
        // Trigger a first load
        extend()
    }
    
    public func extend() {
        extendTriggerSubject.onNext(1)
    }
    
    public func extend(to: Int) {
        Observable.just(1)
            .withLatestFrom(limitsSubject)
            .filter { (limits) -> Bool in
                to > limits.end
        }
        .subscribe(onNext: { [weak self] (_) in
            self?.extendTriggerSubject.onNext(1)
        })
            .disposed(by: bag)
    }
    
}
