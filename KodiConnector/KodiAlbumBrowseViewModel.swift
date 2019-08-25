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

    
    public private(set) var availableSortOptions = [SortType]()
    
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
                reload(genre: genre, sort: sort)
            case let .artist(artist):
                reload(artist: artist, sort: sort)
            case let .recent(duration):
                reload(recent: duration, sort: sort)
            case let .random(count):
                reload(random: count, sort: sort)
            default:
                fatalError("KodiAlbumBrowseViewModel: unsupported filter type")
            }
        }
        else {
            reload(sort: sort)
        }
    }
    
    private func reload(genre: Genre? = nil, artist: Artist? = nil, recent: Int? = nil, random: Int? = nil, sort: SortType) {
        if let recent = recent {
            loadProgress.accept(.loading)
            kodi.getRecentAlbums(count: recent)
                .do() { [weak self] in
                    self?.loadProgress.accept(.dataAvailable)
                }
                .map({ [weak self] (kodiAlbums) -> [Album] in
                    guard let weakSelf = self else { return [] }
                    
                    return kodiAlbums.albums.map({ (kodiAlbum) -> Album in
                        kodiAlbum.album(kodiAddress: weakSelf.kodi.kodiAddress)
                    })
                })
                .bind(to: albumsSubject)
                .disposed(by: bag)
            return
        }
        else if let artist = artist {
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
                .flatMapFirst { (artistId) -> Observable<KodiAlbums> in
                    kodi.getAlbums(artistid: artistId)
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
                .bind(to: albumsSubject)
                .disposed(by: bag)
            return
        }
        else if let genre = genre {
            guard let genreId = Int(genre.id) else {
                return
            }

            loadProgress.accept(.loading)
            kodi.getAlbums(genreid: genreId)
                .do() { [weak self] in
                    self?.loadProgress.accept(.dataAvailable)
                }
                .map({ [weak self] (kodiAlbums) -> [Album] in
                    guard let weakSelf = self else { return [] }
                    
                    return kodiAlbums.albums.map({ (kodiAlbum) -> Album in
                        kodiAlbum.album(kodiAddress: weakSelf.kodi.kodiAddress)
                    })
                })
                .bind(to: albumsSubject)
                .disposed(by: bag)
            return
        }

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
                return kodi.getAlbums(start: limits.end, end: limits.end + 100)
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
            .bind(to: albumsSubject)
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
