//
//  KodiFolderBrowseViewModel.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
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
    
    public func extend() {
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
            .map { (kodiFiles) -> [FolderContent] in
                kodiFiles.files.compactMap({ (kodiFile) -> FolderContent? in
                    kodiFile.folderContent
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
