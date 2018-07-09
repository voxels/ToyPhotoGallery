//
//  NetworkSessionInterface.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/6/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
import AWSCore
import AWSMobileClient
import AWSS3

typealias TaskMap = [String:NetworkSessionTask]

/// Class used to wrap URLSession for handling data and download session tasks
class NetworkSessionInterface : NSObject {
    
    /// A default configuration used for the URLSession
    static let defaultConfiguration = URLSessionConfiguration.default
    
    /// The default timeout used for URLSession requests
    static let defaultTimeout:TimeInterval = 30
    
    /// The default cache policy used for URLSession requests
    static let defaultCachePolicy:URLRequest.CachePolicy = FeaturePolice.disableCache ? .reloadIgnoringLocalAndRemoteCacheData : .returnCacheDataElseLoad
    
    /// An operation queue used to facilitate the URLSession
    let operationQueue = OperationQueue()
    
    /// The error handler delegate used to report non-fatal errors
    let errorHandler:ErrorHandlerDelegate
    
    /// A map of the enqueue tasks that have not completed
    var enqueued = TaskMap()
    
    /// The URLSession used for requests
    var session:URLSession?
    
    init(with errorHandler:ErrorHandlerDelegate) {
        self.errorHandler = errorHandler
        super.init()
        operationQueue.maxConcurrentOperationCount = 1
        session = session(with: FeaturePolice.networkInterfaceUsesEphemeralSession ? .ephemeral : URLSessionConfiguration.default, queue: operationQueue)
    }
    
    /**
     Uses a one-off URLSession, NOT the interface's session, to perform a quick fetch of a data task for the given URL
     - parameter url: the URL being fetched
     - parameter compeletion: a callback used to pass through the optional fetched *Data*
     - Returns: void
     */
    func fetch(url:URL, with session:URLSession? = nil, completion:@escaping (Data?)->Void) {
        // Using a default session here may crash because of a potential bug in Foundation.
        // Ephemeral and Shared sessions don't crash.
        // See: https://forums.developer.apple.com/thread/66874
        
        if NetworkSessionInterface.isAWS(url: url), let filename = filename(for: url) {
            fetchWithAWS(filename: filename, completion: completion)
            return
        }
        
        let useSession = session != nil ? session : FeaturePolice.networkInterfaceUsesEphemeralSession ? URLSession(configuration: .ephemeral) : URLSession(configuration: .default)
        
        let taskCompletion:((Data?, URLResponse?, Error?) -> Void) = { [weak self] (data, response, error) in
            if let e = error {
                self?.errorHandler.report(e)
                completion(nil)
                return
            }
            
            completion(data)
        }
        
        guard let task = useSession?.dataTask(with: url, completionHandler: taskCompletion) else {
            completion(nil)
            return
        }
        
        task.resume()
    }
    
    
    
    // TODO: Implement: https://docs.aws.amazon.com/aws-mobile/latest/developerguide/how-to-transfer-files-with-transfer-utility.html
    /**
     Intercept for fetching AWS urls since they fail with URLSession
     - parameter filename: the key *String* for the file
     - parameter completion: the callback used for the data
     */
    func fetchWithAWS(filename:String, completion:@escaping (Data?)->Void) {
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = {(task, progress) in DispatchQueue.main.async(execute: {
            // Do something e.g. Update a progress bar.
        })
        }
        
        var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
        completionHandler = { [weak self] (task, URL, data, error) -> Void in
            if let error = error {
                self?.errorHandler.report(error)
            }
            completion(data)
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        transferUtility.downloadData(
            fromBucket: "com-federalforge-repository",
            key: filename,
            expression: expression,
            completionHandler: completionHandler
            ).continueWith {
                (task) -> AnyObject? in if let error = task.error {
                    self.errorHandler.report(error)
                }
                
                if let _ = task.result {
                    // Do something with downloadTask.
                    
                }
                return nil;
        }
    }
    
    /**
     Calculates the AWS filename from the given URL
     - parameter AWSUrl: the aws url
     - Returns: a *String* or nil if none is found
    */
    func filename(for AWSUrl:URL)->String? {
        let components = AWSUrl.absoluteString.split(separator: "/")
        var filename = ""
        for index in 3..<components.count {
            filename.append(String(components[index]))
            if index < components.count - 1 {
                filename.append("/")
            }
        }
        return filename
    }
    
    /**
     Constructs a session with the given configuration and queue
     - parameter configuration: The *URLSessionConfiguration* intended for the session
     - parameter queue: the *OperationQueue* used to facilitate the session
     - Returns: a configured *URLSession*
     */
    func session(with configuration:URLSessionConfiguration, queue:OperationQueue) -> URLSession {
        if #available(iOS 11.0, *) {
            configuration.waitsForConnectivity = true
        }
        
        return URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
    }
    
    /**
     Attempts to create a *NetworkSessionTask* with the given parameters and enqueue it into the interface's *TaskMap*
     - parameter url: the *URL* for the task
     - parameter session: the *URLSession* used to handle the task
     - parameter cachePolicy: the *URLRequest.CachePolicy* used to perform the task.  Defaults to the interface's *defaultCachePolicy*
     - parameter timeoutInterval: the *TimeInterval* used to wait for a response.  Defaults to the interface's *defaultTimeout*
     - parameter retain: a *Bool* flag used to indicate if the session task response should be cached locally
     - parameter dataDelegate: an optional *NetworkSessionInterfaceDataTaskDelegate* that will be informed of the task's progress
     - Returns: a *NetworkSessionTask* or nil if one cannot be created
     */
    func sessionTask(with url:URL, in session:URLSession, cachePolicy: URLRequest.CachePolicy = NetworkSessionInterface.defaultCachePolicy, timeoutInterval: TimeInterval = NetworkSessionInterface.defaultTimeout, retain:Bool, dataDelegate:NetworkSessionInterfaceDataTaskDelegate?) throws -> NetworkSessionTask? {
        
        if NetworkSessionInterface.isAWS(url: url) {
            throw NetworkError.AWSDoesNotSupportSessionTasks
        }
        
        let request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        let task = session.dataTask(with: request)
        return enqueue(task: task, retain:retain, dataDelegate:dataDelegate)
    }
    
    /**
     Creates a *NetworkSessionTask* instance from an *URLSessionTask*, and enqueues the task into the interface's *TaskMap* instance
     - parameter task: the *URLSessionTask* to enqueue
     - parameter retain: a *Bool* flag used to indicate if the session task response should be cached locally
     - parameter dataDelegate: an optional *NetworkSessionInterfaceDataTaskDelegate* that will be informed of the task's progress
     - Returns: the enqueued *NetworkSessionTask*
     */
    func enqueue(task:URLSessionTask, retain:Bool, dataDelegate:NetworkSessionInterfaceDataTaskDelegate?) -> NetworkSessionTask {
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
    
    /**
     Cancels and dequeues the given *NetworkSessionTask*
     - parameter sessionTask: the task to cancel
     - Returns: void
     */
    func cancel(_ sessionTask:NetworkSessionTask) {
        sessionTask.task.cancel()
        dequeue(sessionTask)
    }
    
    /**
     Dequeues the given *NetworkSessionTask*
     - parameter sessionTask: the task to cancel
     - Returns: void
     */
    func dequeue(_ sessionTask:NetworkSessionTask) {
        enqueued.removeValue(forKey: sessionTask.uuid)
    }
    
    /**
     Lookup for a session task in the interface's *TaskMap* given the task's UUID
     - parameter uuid: a option *String* for the *NetworkSessionTask*'s identifier
     - Returns: the enqueued *NetworkSessionTask* or nil if one cannot be found
     */
    func sessionTask(for uuid:String?)->NetworkSessionTask? {
        guard let uuid = uuid else {
            return nil
        }
        return enqueued[uuid]
    }
}

extension NetworkSessionInterface {
    /**
     Returns the *NetworkSessionInterfaceDataTaskDelegate* for a given *URLSessionDataTask*
     - parameter dataTask: the *URLSessionDataTask* that needs to report to its delegate
     - Returns: a *NetworkSessionInterfaceDataTaskDelegate* for the data task if one can be found
     */
    func dataDelegate(for dataTask:URLSessionDataTask)->NetworkSessionInterfaceDataTaskDelegate? {
        if let existingTask = sessionTask(for: dataTask.taskDescription), let dataDelegate = existingTask.dataDelegate {
            return dataDelegate
        }
        
        return nil
    }
    
    /**
     Retains the network session task's data to the given location
     UNIMPLEMENTED
     */
    func retainIfNecessary(task:NetworkSessionTask?, from location:URL) throws {
        /*
         guard let _ = task else {
         return
         }
         
         debugPrint("Download finished: \(location)")
         // TODO: Save to disk
         try? FileManager.default.removeItem(at: location)
         */
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
    
    /// Checks if a URL is from S3, because S3 needs its own network manager
    static func isAWS(url:URL)->Bool {
        return url.absoluteString.contains(NetworkSessionInterface.awsURLString)
    }
}
