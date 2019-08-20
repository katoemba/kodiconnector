//
//  KodiArtistBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import ConnectorProtocol

public class KodiArtistBrowseViewModel: ArtistBrowseViewModel {
    private var loadProgress = BehaviorRelay<LoadProgress>(value: .notStarted)
    public var loadProgressObservable: Observable<LoadProgress> {
        return loadProgress.asObservable()
    }
    
    private var artistSectionsSubject = ReplaySubject<ArtistSections>.create(bufferSize: 1)
    public var artistSectionsObservable: Observable<ArtistSections> {
        return artistSectionsSubject.asObservable()
    }
    private var artists: [Artist]?
    public private(set) var filters: [BrowseFilter]
    
    public private(set) var artistType = ArtistType.artist
    
    private var kodi: KodiProtocol
    private var bag = DisposeBag()
    
    public init(kodi: KodiProtocol, filters: [BrowseFilter] = [], artists: [Artist]? = nil) {
        self.kodi = kodi
        self.filters = filters
        self.artists = artists
    }
    
    public func load(filters: [BrowseFilter]) {
        self.filters = filters
        load()
    }

    public func load() {
        // Get rid of old disposables
        bag = DisposeBag()
        
        // Clear the contents
        loadProgress.accept(.loading)
        
        var artistObservable: Observable<[Artist]>
        var multiSection: Bool
        
        if let artists = artists {
            multiSection = false
            artistObservable = Observable.just(artists).share(replay: 1)
        }
        else {
            multiSection = true
            artistObservable = kodi.getArtists(start: 0, end: 100000, albumartistsonly: true)
                .map({ (kodiArtists) -> [Artist] in
                    kodiArtists.artists.map({ (kodiArtist) -> Artist in
                        kodiArtist.artist
                    })
                })
                .observeOn(MainScheduler.instance)
                .share(replay: 1)
        }

        artistObservable
            .filter({ (artists) -> Bool in
                artists.count > 0
            })
            .map({ (artists) -> [(String, [Artist])] in
                guard multiSection == true else {
                    return [("", artists)]
                }
                
                let dict = Dictionary(grouping: artists, by: { artist -> String in
                    var firstLetter: String
                    
                    firstLetter = String(artist.sortName.prefix(1)).uppercased()
                    if "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(firstLetter) == false {
                        firstLetter = "•"
                    }
                    return firstLetter
                })
                
                // Create an ordered array of LibraryItemsSections from the dictionary
                return dict.keys
                    .sorted()
                    .map({ (key) -> (String, [Artist]) in
                        (key, dict[key]!)
                    })
            })
            .map({ (sectionDictionary) -> ArtistSections in
                ArtistSections(sectionDictionary, completeObjects: { (artists) -> Observable<[Artist]> in
                    return Observable.just(artists)
                })
            })
            .subscribe(onNext: { [weak self] (objectSections) in
                self?.artistSectionsSubject.onNext(objectSections)
            })
            .disposed(by: bag)
        
        artistObservable
            .filter { (artists) -> Bool in
                artists.count == 0
            }
            .map { (_) -> LoadProgress in
                .noDataFound
            }
            .bind(to: loadProgress)
            .disposed(by: bag)
        
        artistObservable
            .filter({ (artists) -> Bool in
                artists.count > 0
            })
            .map { (_) -> LoadProgress in
                .allDataLoaded
            }
            .bind(to: loadProgress)
            .disposed(by: bag)
    }
    
}
