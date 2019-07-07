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
    
    private var artistSectionsSubject = PublishSubject<ObjectSections<Artist>>()
    public var artistSectionsObservable: Observable<ObjectSections<Artist>> {
        return artistSectionsSubject.asObservable()
    }
    
    public private(set) var filters = [BrowseFilter]()
    
    public private(set) var artistType = ArtistType.artist
    
    public func load() {
    }
    
    public func load(filters: [BrowseFilter]) {
    }
    
    public func extend() {
    }
    
}
