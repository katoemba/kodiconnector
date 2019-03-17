//
//  KodiStatus.swift
//  KodiConnector
//
//  Created by Berrie Kremers on 10/03/2019.
//  Copyright © 2019 Katoemba Software. All rights reserved.
//

import Foundation
import ConnectorProtocol
import RxSwift
import RxCocoa

public class KodiStatus: StatusProtocol {
    private var kodi: KodiProtocol
    private var connectionStatus = BehaviorRelay<ConnectionStatus>(value: .unknown)
    public var connectionStatusObservable: Observable<ConnectionStatus> {
        return connectionStatus.asObservable()
    }
    
    private var playerStatus = BehaviorRelay<PlayerStatus>(value: PlayerStatus())
    public var playerStatusObservable: Observable<PlayerStatus> {
        return playerStatus.asObservable()
    }
    
    private var lastKnownElapsedTime = 0
    private var lastKnownElapsedTimeRecorded = Date()

    private var statusScheduler: SchedulerType
    private var elapsedTimeScheduler: SchedulerType
    private var bag = DisposeBag()
    
    public init(kodi: KodiProtocol,
                scheduler: SchedulerType? = nil) {
        self.kodi = kodi
        if scheduler == nil {
            self.statusScheduler = SerialDispatchQueueScheduler.init(qos: .background, internalSerialQueueName: "com.katoemba.mpdconnector.status")
            self.elapsedTimeScheduler = SerialDispatchQueueScheduler.init(internalSerialQueueName: "com.katoemba.mpdconnector.elapsedtime")
        }
        else {
            self.statusScheduler = scheduler!
            self.elapsedTimeScheduler = scheduler!
        }
    }
    
    public func startMonitoring() {
        let kodi = self.kodi
        
        connectionStatus.accept(.online)
        
        let playerStatusSubject = self.playerStatus
        Observable<Int>
            .timer(RxTimeInterval(1.0), period: RxTimeInterval(1.0), scheduler: elapsedTimeScheduler)
            .map({ [weak self] (_) -> PlayerStatus? in
                guard let weakSelf = self, weakSelf.playerStatus.value.playing.playPauseMode == .Playing else { return nil }

                var newPlayerStatus = PlayerStatus.init(weakSelf.playerStatus.value)
                newPlayerStatus.time.elapsedTime = weakSelf.lastKnownElapsedTime + Int(Date().timeIntervalSince(weakSelf.lastKnownElapsedTimeRecorded))
                return newPlayerStatus
            })
            .filter({ (playerStatus) -> Bool in
                playerStatus != nil
            })
            .map({ (playerStatus) -> PlayerStatus in
                playerStatus!
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (playerStatus) in
                playerStatusSubject.accept(playerStatus)
            })
            .disposed(by: bag)
        
        Observable<Int>
            .timer(RxTimeInterval(0.0), period: RxTimeInterval(5.0), scheduler: statusScheduler)
            .flatMap({ [weak self] (_) -> Observable<PlayerStatus> in
                guard let weakSelf = self else { return Observable.just(PlayerStatus()) }
                return weakSelf.getStatus()
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (playerStatus) in
                playerStatusSubject.accept(playerStatus)
            })
            .disposed(by: bag)
    }
    
    public func stopMonitoring() {
    
    }
    
    public func playqueueSongs(start: Int, end: Int) -> Observable<[Song]> {
        return kodi.getPlayQueue(start: start, end: end)
    }
    
    public func forceStatusRefresh() {
        let playerStatusSubject = self.playerStatus
        getStatus()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (playerStatus) in
                playerStatusSubject.accept(playerStatus)
            })
            .disposed(by: bag)
    }
    
    public func getStatus() -> Observable<PlayerStatus> {
        let kodi = self.kodi
        return kodi.getActivePlayers()
            .flatMap { (_) -> Observable<KodiPlayerProperties> in
                return kodi.getPlayerProperties()
            }
            .map({ (playerProperties) -> PlayerStatus in
                var playerStatus = PlayerStatus()
                playerStatus.lastUpdateTime = Date()
                playerStatus.playing.randomMode = playerProperties.shuffled ? .On : .Off
                playerStatus.playing.repeatMode = (playerProperties.repeat == "all") ? .All : ( (playerProperties.repeat == "one") ? .Single : .Off)
                playerStatus.time.elapsedTime = playerProperties.elapsedTime
                playerStatus.time.trackTime = playerProperties.totalTime
                playerStatus.playing.playPauseMode = playerProperties.speed == 1 ? .Playing : .Paused
                
                playerStatus.playqueue.songIndex = playerProperties.position
                
                return playerStatus
            })
            .flatMap({ (playerStatus) -> Observable<PlayerStatus> in
                kodi.getCurrentSong()
                    .map({ (song) -> PlayerStatus in
                        var updatedPlayerStatus = playerStatus
                        updatedPlayerStatus.currentSong = song
                        return updatedPlayerStatus
                    })
            })
    }
}
