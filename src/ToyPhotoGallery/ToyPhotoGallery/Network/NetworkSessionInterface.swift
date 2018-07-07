//
//  NetworkSessionInterface.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/6/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

struct DownloadTask {
    var task:URLSessionDownloadTask
    var retain:Bool
    var dataLocation:String?
}

typealias TaskMap = [Data:DownloadTask]

class NetworkSessionInterface : NSObject {
    var queuedTasks = TaskMap()
    
    static let defaultConfiguration = URLSessionConfiguration.default
    static let defaultTimeout:TimeInterval = 30
    static let defaultCachePolicy:URLRequest.CachePolicy = .reloadRevalidatingCacheData
    let operationQueue = OperationQueue()
    let errorHandler:ErrorHandlerDelegate
    
    init(with errorHandler:ErrorHandlerDelegate) {
        self.errorHandler = errorHandler
        super.init()
        operationQueue.maxConcurrentOperationCount = 5
    }
    
    func session(with configuration:URLSessionConfiguration, queue:OperationQueue) -> URLSession {
        return URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
    }
    
    func downloadFile(from url:URL, with session:URLSession, cachePolicy: URLRequest.CachePolicy = NetworkSessionInterface.defaultCachePolicy, timeoutInterval: TimeInterval = NetworkSessionInterface.defaultTimeout, retain:Bool) {
        let request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        let task = session.downloadTask(with: request)
        do {
            try enqueue(download: task, retain:retain)
        } catch {
            errorHandler.report(error)
        }
    }
    
    func enqueue(download task:URLSessionDownloadTask, retain:Bool) throws {
        guard let request = task.originalRequest, let url = request.url else {
            throw NetworkError.DownloadTaskIsMissingURLRequest
        }
        
        let key = identifier(for: url)
        var shouldEnqueue = false
        if let existingTask = queuedTasks[key], existingTask.task.state == .running {
            switch existingTask.task.state {
            case .canceling:
                fallthrough
            case .completed:
                fallthrough
            case .suspended:
                queuedTasks.removeValue(forKey: key)
                shouldEnqueue = true
            case .running:
                break
            }
        }
        
        if shouldEnqueue {
            let downloadTask = DownloadTask(task: task, retain: retain, dataLocation: nil)
            queuedTasks[key] = downloadTask
            downloadTask.task.resume()
        }
    }
}

extension NetworkSessionInterface {
    func identifier(for url:URL)->Data {
        return Data.MD5(string: url.absoluteString)
    }
    
    func retainIfNecessary(task:DownloadTask?, from location:URL) throws {
        guard let task = task else {
            return
        }
        
        debugPrint("Download finished: \(location)")
        
        try? FileManager.default.removeItem(at: location)
    }
}

extension NetworkSessionInterface : URLSessionTaskDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let taskURL = downloadTask.originalRequest?.url else {
            return
        }
        let key = identifier(for: taskURL)
        do {
            try retainIfNecessary(task: queuedTasks[key], from: location)
        } catch {
            errorHandler.report(error)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let e = error {
            errorHandler.report(e)
            assert(false, e.localizedDescription)
        }
    }
    
    // Standard background session handler
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }
}
