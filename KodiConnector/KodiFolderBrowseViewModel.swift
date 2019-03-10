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

    public private(set) var parentFolder = nil as Folder?
    
    public func load() {
    }
    
    public func extend() {
    }
    
}
