//
//  NetworkSessionInterface.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/6/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

class NetworkSessionTask : Hashable {
    var uuid:String = ""
    var task:URLSessionTask
    var retain:Bool = false
    var dataLocation:String?
    weak var dataDelegate:NetworkSessionInterfaceDataTaskDelegate?
    
    init(with uuid:String, task:URLSessionTask, retain:Bool, dataDelegate:NetworkSessionInterfaceDataTaskDelegate?) {
        self.uuid = uuid
        self.task = task
        self.retain = retain
        self.dataDelegate = dataDelegate
    }
    
    var hashValue: Int {
        return task.hashValue ^ uuid.hashValue &* 16777619
    }
    
    static func == (lhs: NetworkSessionTask, rhs: NetworkSessionTask) -> Bool {
        return lhs.task == rhs.task && lhs.uuid == rhs.uuid
    }
}

typealias TaskMap = [String:NetworkSessionTask]

protocol NetworkSessionInterfaceDataTaskDelegate : class {
    var uuid:String { get }
    func didReceive(data: Data, for uuid:String?) throws
    func didReceive(response: URLResponse, for uuid:String?)
    func didFinish(uuid:String?)
    func didFail(uuid:String?, with error:URLError)
}

class NetworkSessionInterface : NSObject {
    static let defaultConfiguration = URLSessionConfiguration.default
    static let defaultTimeout:TimeInterval = 30
    static let defaultCachePolicy:URLRequest.CachePolicy = .returnCacheDataElseLoad

    let operationQueue = OperationQueue()
    let errorHandler:ErrorHandlerDelegate
    var enqueued = TaskMap()
    var session:URLSession?

    init(with errorHandler:ErrorHandlerDelegate) {
        self.errorHandler = errorHandler
        super.init()
        operationQueue.maxConcurrentOperationCount = 1
        session = session(with: URLSessionConfiguration.default, queue: operationQueue)
    }
    
    func fetch(url:URL, completion:@escaping (Data?)->Void) {
        let task = URLSession(configuration: .default, delegate: nil, delegateQueue: nil).dataTask(with: url) { [weak self] (data, response, error) in
            if let e = error {
                self?.errorHandler.report(e)
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            completion(data)
        }
        task.resume()
    }
    
    func session(with configuration:URLSessionConfiguration, queue:OperationQueue) -> URLSession {
        if #available(iOS 11.0, *) {
            configuration.waitsForConnectivity = true
        }
        
        return URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
    }
    
    func sessionTask(with url:URL, in session:URLSession, cachePolicy: URLRequest.CachePolicy = NetworkSessionInterface.defaultCachePolicy, timeoutInterval: TimeInterval = NetworkSessionInterface.defaultTimeout, retain:Bool, dataDelegate:NetworkSessionInterfaceDataTaskDelegate?) -> NetworkSessionTask? {
        
        if NetworkSessionInterface.isAWS(url: url) {
            #if !DEBUG
            errorHandler.report(NetworkError.AWSDoesNotSupportSessionTasks)
            #endif
            return nil
        }
        
        let request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        let task = session.dataTask(with: request)
        return enqueue(task: task, retain:retain, dataDelegate:dataDelegate)
    }
    
    func enqueue<T>(task:T, retain:Bool, dataDelegate:NetworkSessionInterfaceDataTaskDelegate?) -> NetworkSessionTask where T:URLSessionTask {
        let checkUUID = dataDelegate?.uuid ?? UUID().uuidString
        
        if let sessionTask = enqueued[checkUUID] {
            if sessionTask.task.state != .running {
                dequeue(sessionTask)
            }
            else {
                return sessionTask
            }
        }
        
        let sessionTask = NetworkSessionTask(with:checkUUID, task: task, retain: retain, dataDelegate:dataDelegate)
        sessionTask.task.taskDescription = sessionTask.uuid
        enqueued[sessionTask.uuid] = sessionTask
        return sessionTask
    }
    
    func cancel(_ sessionTask:NetworkSessionTask) {
        sessionTask.task.cancel()
        dequeue(sessionTask)
    }
    
    func dequeue(_ sessionTask:NetworkSessionTask) {
        enqueued.removeValue(forKey: sessionTask.uuid)
    }
    
    func sessionTask(for uuid:String?)->NetworkSessionTask? {
        guard let uuid = uuid else {
            return nil
        }
        return enqueued[uuid]
    }
}

extension NetworkSessionInterface {
    func dataDelegate(for dataTask:URLSessionDataTask)->NetworkSessionInterfaceDataTaskDelegate? {
        if let existingTask = sessionTask(for: dataTask.taskDescription), let dataDelegate = existingTask.dataDelegate {
            return dataDelegate
        }
        
        return nil
    }
    
    func retainIfNecessary(task:NetworkSessionTask?, from location:URL) throws {
        guard let _ = task else {
            return
        }
        
        debugPrint("Download finished: \(location)")
        // TODO: Save to disk
        try? FileManager.default.removeItem(at: location)
    }
}

extension NetworkSessionInterface : URLSessionTaskDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let protectionSpace = challenge.protectionSpace
        let authMethod = challenge.protectionSpace.authenticationMethod
        
        guard authMethod == NSURLAuthenticationMethodServerTrust, protectionSpace.host.contains("s3.amazonaws.com") else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        do {
            try handleAWS(with: protectionSpace, completionHandler: completionHandler)
        } catch {
            errorHandler.report(error)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    func handleAWS(with protectionSpace:URLProtectionSpace, completionHandler:@escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) throws {
        guard let serverTrust = protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        if checkValidity(of: serverTrust) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Show a UI here warning the user the server credentials are
            // invalid, and cancel the load.
            throw NetworkError.InvalidServerTrust
        }
    }
    
    // TODO: Implement checkValidity
    func checkValidity(of:SecTrust) -> Bool {
        return false
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse {
            if (200...299).contains(httpResponse.statusCode) {
                if let existingTask = sessionTask(for: dataTask.taskDescription), existingTask.retain {
                    completionHandler(.becomeDownload)
                } else {
                    completionHandler(.allow)
                }
                if let dataDelegate = dataDelegate(for: dataTask) {
                    dataDelegate.didReceive(response: response, for: dataTask.taskDescription)
                }
            } else {
                #if DEBUG
                let logHandler = DebugLogHandler()
                logHandler.console("Received status code \(httpResponse.statusCode) for url: \(response.url?.absoluteString ?? "unknown")")
                #endif
                completionHandler(.cancel)
            }
        } else {
            completionHandler(.cancel)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let dataDelegate = dataDelegate(for: dataTask) {
            do {
                try dataDelegate.didReceive(data: data, for:dataTask.taskDescription)
            } catch {
                errorHandler.report(error)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let dataTask = task as? URLSessionDataTask, let dataDelegate = dataDelegate(for: dataTask) {
            if let e = error as? URLError {
                switch e {
                case URLError.cancelled:
                    break
                default:
                    dataDelegate.didFail(uuid:task.taskDescription, with: e)
                    errorHandler.report(e)
                }
            } else {
                dataDelegate.didFinish(uuid:task.taskDescription)
            }
        }
        
        if let sessionTask = sessionTask(for: task.taskDescription) {
            dequeue(sessionTask)
        }
    }
    
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

extension NetworkSessionInterface :  URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let sessionTask = sessionTask(for: downloadTask.taskDescription) {
            do {
                try retainIfNecessary(task: sessionTask, from: location)
            } catch {
                errorHandler.report(error)
            }
        }
    }
}

extension NetworkSessionInterface {
    static let awsURLString = "s3.amazonaws.com"
    
    static func isAWS(url:URL)->Bool {
        return url.absoluteString.contains(NetworkSessionInterface.awsURLString)
    }
}
