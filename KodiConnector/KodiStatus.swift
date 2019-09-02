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
import RxSwiftExt
import Starscream

public class KodiStatus: StatusProtocol {
    private var kodi: KodiProtocol
    private var connectionStatus = ReplaySubject<ConnectionStatus>.create(bufferSize: 1)
    public var connectionStatusObservable: Observable<ConnectionStatus> {
        return connectionStatus.asObservable()
    }
    
    private var playerStatus = ReplaySubject<PlayerStatus>.create(bufferSize: 1)
    public var playerStatusObservable: Observable<PlayerStatus> {
        return playerStatus.asObservable()
    }
    
    private var lastKnownElapsedTime = 0
    private var lastKnownElapsedTimeRecorded = Date()

    private var elapsedTimeScheduler: SchedulerType
    private var bag = DisposeBag()
    
    private var socket: WebSocket
    
    public init(kodi: KodiProtocol,
                scheduler: SchedulerType? = nil) {
        self.kodi = kodi
        
        if scheduler == nil {
            self.elapsedTimeScheduler = SerialDispatchQueueScheduler.init(internalSerialQueueName: "com.katoemba.mpdconnector.elapsedtime")
        }
        else {
            self.elapsedTimeScheduler = scheduler!
        }

        socket = WebSocket(url: URL(string: "ws://\(kodi.kodiAddress.ip):\(kodi.kodiAddress.websocketPort)/jsonrpc")!)
        initWebSocket(socket)
        
        // Setup a timer to forward the seek value when monitoring
        let playerStatusSubject = self.playerStatus
        Observable<Int>
            .timer(RxTimeInterval.seconds(1), period: RxTimeInterval.seconds(1), scheduler: elapsedTimeScheduler)
            .filter({ [weak self] (_) -> Bool in
                self?.socket.isConnected ?? false
            })
            .withLatestFrom(playerStatus)
            .map({ [weak self] (playerStatus) -> PlayerStatus? in
                guard let weakSelf = self, playerStatus.playing.playPauseMode == .Playing else { return nil }
                
                var newPlayerStatus = playerStatus
                newPlayerStatus.time.elapsedTime = weakSelf.lastKnownElapsedTime + Int(Date().timeIntervalSince(weakSelf.lastKnownElapsedTimeRecorded))
                return newPlayerStatus
            })
            .unwrap()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (playerStatus) in
                playerStatusSubject.onNext(playerStatus)
            })
            .disposed(by: bag)
    }
    
    deinit {
        socket.disconnect()
    }
    
    public func startMonitoring() {
        socket.connect()
    }
    
    public func stopMonitoring() {
        socket.disconnect()
    }
    
    public func kodiSettingsChanged(kodi: KodiProtocol) {
        guard kodi.kodiAddress.websocketPort != self.kodi.kodiAddress.websocketPort else { return }
        
        if socket.isConnected {
            socket.disconnect()
        }
        
        self.kodi = kodi
        socket = WebSocket(url: URL(string: "ws://\(kodi.kodiAddress.ip):\(kodi.kodiAddress.websocketPort)/jsonrpc")!)
        initWebSocket(socket)
        
        socket.connect()
    }
    
    public func playqueueSongs(start: Int, end: Int) -> Observable<[Song]> {
        return kodi.getPlayQueue(start: start, end: end)
            .map({ [weak self] (kodiSongs) -> [Song] in
                guard let weakSelf = self else { return [] }

                var position = start
                return kodiSongs.map({ (kodiSong) -> Song in
                    var song = kodiSong.song(kodiAddress: weakSelf.kodi.kodiAddress)
                    song.position = position
                    position += 1
                    
                    return song
                })
            })
    }
    
    public func forceStatusRefresh() {
        let playerStatusSubject = self.playerStatus
        getStatus()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (playerStatus) in
                playerStatusSubject.onNext(playerStatus)
            })
            .disposed(by: bag)
    }
    
    public func getStatus() -> Observable<PlayerStatus> {
        let kodi = self.kodi
        return kodi.getActivePlayers()
            .flatMap { (_) -> Observable<KodiPlayerProperties> in
                return kodi.getPlayerProperties()
            }
            .map({ [weak self] (playerProperties) -> PlayerStatus in
                self?.lastKnownElapsedTime = playerProperties.time.timeInSeconds
                self?.lastKnownElapsedTimeRecorded = Date()
                return playerProperties.playerStatus
            })
            .flatMap({ (playerStatus) -> Observable<PlayerStatus> in
                kodi.getApplicationProperties()
                    .map({ (_, _, volume) -> PlayerStatus in
                        var updatedPlayerStatus = playerStatus
                        updatedPlayerStatus.volume = Float(volume) / 100.0
                        return updatedPlayerStatus
                    })
            })
            .flatMap({ (playerStatus) -> Observable<PlayerStatus> in
                kodi.getCurrentSong()
                    .map({ [weak self] (song) -> PlayerStatus in
                        guard let weakSelf = self else { return PlayerStatus() }

                        var updatedPlayerStatus = playerStatus
                        updatedPlayerStatus.currentSong = song.song(kodiAddress: weakSelf.kodi.kodiAddress)
                        return updatedPlayerStatus
                    })
            })
    }
    
    private func initWebSocket(_ socket: WebSocket) {
        //websocketDidConnect
        socket.onConnect = { [weak self] in
            guard let weakSelf = self else { return }
            
            weakSelf.connectionStatus.onNext(.online)
            weakSelf.getStatus()
                .subscribe(onNext: { [weak self] playerStatus in
                    self?.playerStatus.onNext(playerStatus)
                })
                .disposed(by: weakSelf.bag)
            
            print("websocket is connected")
        }
        //websocketDidDisconnect
        socket.onDisconnect = { [weak self] (error: Error?) in
            self?.connectionStatus.onNext(.offline)
            print("websocket is disconnected: \(error?.localizedDescription)")
        }
        //websocketDidReceiveMessage
        socket.onText = { [weak self] (text: String) in
            guard let weakSelf = self else { return }

            print("got some text: \(text)")
            if let data = text.data(using: .utf8), let notification = weakSelf.kodi.parseNotification(data) {
                print("Notification: \(notification)")
                weakSelf.processNotification(notification)
            }
        }
        //websocketDidReceiveData
        socket.onData = { (data: Data) in
            print("got some data: \(data.count)")
        }
    }
    
    private func processNotification(_ notification: Notification) {
        Observable.just(1)
            .withLatestFrom(playerStatusObservable)
            .subscribe(onNext: { [weak self] (playerStatus) in
                guard let weakSelf = self else { return }
                
                switch notification {
                case is PlayerOnSeek:
                    weakSelf.playerStatus.onNext(weakSelf.processSeekNotification(notification: notification as! PlayerOnSeek,
                                                                                  into: playerStatus))
                case is PlayerOnStop:
                    weakSelf.playerStatus.onNext(weakSelf.processStopNotification(notification: notification as! PlayerOnStop,
                                                                                  into: playerStatus))
                case is PlayerOnPause:
                    weakSelf.playerStatus.onNext(weakSelf.processPauseNotification(notification: notification as! PlayerOnPause,
                                                                                   into: playerStatus))
                case is PlayerOnPlay:
                    weakSelf.playerStatus.onNext(weakSelf.processPlayNotification(notification: notification as! PlayerOnPlay,
                                                                                  into: playerStatus))
                case is PlayerOnPropertyChanged:
                    weakSelf.playerStatus.onNext(weakSelf.processPropertyChangedNotification(notification: notification as! PlayerOnPropertyChanged,
                                                                                             into: playerStatus))
                case is ApplicationOnVolumeChanged:
                    weakSelf.playerStatus.onNext(weakSelf.processVolumeChangedNotification(notification: notification as! ApplicationOnVolumeChanged,
                                                                                           into: playerStatus))
                default:
                    break
                }
            })
            .disposed(by: bag)
    }
    
    private func processSeekNotification(notification: PlayerOnSeek, into: PlayerStatus) -> PlayerStatus {
        let time = notification.data.player.time!
        
        var playerStatus = updateTimes(playerStatus: into, elapsedTime: time.hours * 3600 + time.minutes * 60 + time.seconds)
        playerStatus.lastUpdateTime = Date()
        
        return playerStatus
    }

    private func processStopNotification(notification: PlayerOnStop, into: PlayerStatus) -> PlayerStatus {
        var playerStatus = into
        playerStatus.playing.playPauseMode = .Stopped
        playerStatus.lastUpdateTime = Date()
        
        return playerStatus
    }

    private func processPauseNotification(notification: PlayerOnPause, into: PlayerStatus) -> PlayerStatus {
        var playerStatus = into
        playerStatus.playing.playPauseMode = .Paused
        playerStatus.lastUpdateTime = Date()
        
        return playerStatus
    }

    private func processPlayNotification(notification: PlayerOnPlay, into: PlayerStatus) -> PlayerStatus {
        var playerStatus = into
        let isPlaying = playerStatus.playing.playPauseMode == .Playing
        
        playerStatus.playing.playPauseMode = .Playing
        playerStatus.lastUpdateTime = Date()
        if playerStatus.currentSong.id != "\(notification.data.item.id)" || isPlaying == true {
            kodi.getCurrentSong()
                .subscribe(onNext: { [weak self] (kodiSong) in
                    guard let weakSelf = self else { return }
                    
                    var playerStatus = weakSelf.updateTimes(playerStatus: playerStatus, elapsedTime: 0, duration: kodiSong.duration)
                    playerStatus.currentSong = kodiSong.song(kodiAddress: weakSelf.kodi.kodiAddress)
                    playerStatus.lastUpdateTime = Date()
                    weakSelf.playerStatus.onNext(playerStatus)
                })
                .disposed(by: bag)
        }
        
        return playerStatus
    }

    private func processPropertyChangedNotification(notification: PlayerOnPropertyChanged, into: PlayerStatus) -> PlayerStatus {
        var playerStatus = into

        if let shuffled = notification.data.property.shuffled {
            playerStatus.playing.randomMode = shuffled ? .On : .Off
        }
        if let `repeat` = notification.data.property.repeat {
            playerStatus.playing.repeatMode = `repeat` == "all" ? .All : (`repeat` == "one" ? .Single : .Off)
        }
        playerStatus.lastUpdateTime = Date()

        return playerStatus
    }
    
    private func processVolumeChangedNotification(notification: ApplicationOnVolumeChanged, into: PlayerStatus) -> PlayerStatus {
        var playerStatus = into
        
        playerStatus.volume = notification.data.muted ? 0.0 : notification.data.volume / 100.0
        playerStatus.lastUpdateTime = Date()
        
        return playerStatus
    }
    
    private func updateTimes(playerStatus: PlayerStatus, elapsedTime: Int, duration: Int? = nil) -> PlayerStatus {
        var playerStatus = playerStatus
        
        playerStatus.time.elapsedTime = elapsedTime
        if let duration = duration {
            playerStatus.time.trackTime = duration
        }
        lastKnownElapsedTime = playerStatus.time.elapsedTime
        lastKnownElapsedTimeRecorded = Date()
        
        return playerStatus
    }
}

extension KodiPlayerProperties {
    var playerStatus: PlayerStatus {
        get {
            var playerStatus = PlayerStatus()
            
            playerStatus.lastUpdateTime = Date()
            playerStatus.playing.randomMode = shuffled ? .On : .Off
            playerStatus.playing.repeatMode = (`repeat` == "all") ? .All : ( (`repeat` == "one") ? .Single : .Off)
            playerStatus.time.elapsedTime = time.timeInSeconds
            playerStatus.time.trackTime = totaltime.timeInSeconds
            playerStatus.playing.playPauseMode = speed == 1 ? .Playing : .Paused
            playerStatus.playqueue.songIndex = position
            
            return playerStatus
        }
    }
}
