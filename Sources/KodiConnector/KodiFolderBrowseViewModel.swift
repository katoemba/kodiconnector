//
//  KodiFolderBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ConnectorProtocol

public class KodiFolderBrowseViewModel: FolderBrowseViewModel {
    private var loadProgress = BehaviorRelay<LoadProgress>(value: .notStarted)
    public var loadProgressObservable: Observable<LoadProgress> {
        return loadProgress.asObservable()
    }

    private var folderContentsSubject = PublishSubject<[FolderContent]>()
    public var folderContentsObservable: Observable<[FolderContent]> {
        return folderContentsSubject.asObservable()
    }

    private var kodi: KodiProtocol
    public private(set) var parentFolder = nil as Folder?
    private let bag = DisposeBag()
    
    public required init(kodi: KodiProtocol, parentFolder: Folder? = nil) {
        self.kodi = kodi
        self.parentFolder = parentFolder
    }
    
    public func load() {
        if let parentFolder = parentFolder {
            reload(parentFolder: parentFolder)
        }
        else {
            reload()
        }
    }
    
    private func reload() {
        loadProgress.accept(.loading)
        
        let foldersObservable = kodi.getSources()
            .map { (kodiSources) -> [FolderContent] in
                kodiSources.sources.map({ (kodiSource) -> FolderContent in
                    .folder(kodiSource.folder)
                })
            }
            .share()
            
        foldersObservable
            .bind(to: folderContentsSubject)
            .disposed(by: bag)

        foldersObservable
            .filter { (folders) -> Bool in
                folders.count == 0
            }
            .map({ (_) -> LoadProgress in
                .noDataFound
            })
            .bind(to: loadProgress)
            .disposed(by: bag)

        foldersObservable
            .filter { (folders) -> Bool in
                folders.count > 0
            }
            .map({ (_) -> LoadProgress in
                .allDataLoaded
            })
            .bind(to: loadProgress)
            .disposed(by: bag)
    }
    
    private func reload(parentFolder: Folder) {
        loadProgress.accept(.loading)
        
        let foldersObservable = kodi.getDirectory(parentFolder.path)
            .map { [weak self] (kodiFiles) -> [FolderContent] in
                guard let weakSelf = self else { return [] }
                guard let files = kodiFiles.files else { return [] }

                return files
                    .compactMap({ (kodiFile) -> FolderContent? in
                        kodiFile.folderContent(kodiAddress: weakSelf.kodi.kodiAddress)
                    })
                    .sorted(by: {
                        if case let .song(song0) = $0, case let .song(song1) = $1 {
                            return song0.disc < song1.disc || (song0.disc == song1.disc && song0.track < song1.track)
                        }
                        
                        var name0 = ""
                        var name1 = ""
                        switch $0 {
                        case let .song(song):
                            name0 = song.title
                        case let .playlist(playlist):
                            name0 = playlist.name
                        case let .folder(folder):
                            name0 = folder.name
                        }
                        switch $1 {
                        case let .song(song):
                            name1 = song.title
                        case let .playlist(playlist):
                            name1 = playlist.name
                        case let .folder(folder):
                            name1 = folder.name
                        }
                        return name0 < name1
                    })
            }
            .share()
        
        foldersObservable
            .bind(to: folderContentsSubject)
            .disposed(by: bag)
        
        foldersObservable
            .filter { (folders) -> Bool in
                folders.count == 0
            }
            .map({ (_) -> LoadProgress in
                .noDataFound
            })
            .bind(to: loadProgress)
            .disposed(by: bag)
        
        foldersObservable
            .filter { (folders) -> Bool in
                folders.count > 0
            }
            .map({ (_) -> LoadProgress in
                .allDataLoaded
            })
            .bind(to: loadProgress)
            .disposed(by: bag)
    }
}
