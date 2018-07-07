//
//  BufferedImageView.swift
//
//  Created by Boris Bügling on 11/03/15.
//  Customized by Michael Edgcumbe on 07/06/18
//  Copyright (c) 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

/// A subclass of UIImageView which displays a JPEG progressively while it is downloaded
class BufferedImageView : UIImageView {

    weak var interface:NetworkSessionInterface?

    var sessionTask:NetworkSessionTask?
    var queue = OperationQueue()
    var uuid:String = UUID().uuidString
    
    var isCancelled = false
    
    let defaultContentLength = 5 * 1024 * 1024
    var data: Data?

    deinit {
        cancel()
    }

    required init(url: Foundation.URL, networkSessionInterface:NetworkSessionInterface?) {
        super.init(image: nil)
        guard let interface = networkSessionInterface, let session = interface.session else {
            return
        }
        queue.maxConcurrentOperationCount = 1
        self.interface = interface
        load(url, with:interface, session:session)
    }

    /// Required initializer, not implemented
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func load(_ url: Foundation.URL, with interface:NetworkSessionInterface, session:URLSession) {
        if isCancelled {
            return
        }
        
        image = nil
        
        if let sessionTask = interface.sessionTask(with: url, in: session, retain: false, dataDelegate:self) {
            sessionTask.task.resume()
        } else {
            fallback(with:url, queue:queue.underlyingQueue ?? .main, interface:interface)
        }
    }
    
    func assign(data:Data?) {
        guard let data = data else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.image = UIImage(data:data)
        }
    }
    
    func fallback(with url:URL, queue:DispatchQueue, interface:NetworkSessionInterface) {
        interface.fetch(url: url, queue: queue) {[weak self] (data) in
            self?.assign(data: data)
        }
    }
}

extension BufferedImageView {
    func add(operation:@escaping ()->Void) {
        let nextOperation = BlockOperation {
            operation()
        }
        nextOperation.qualityOfService = .background
        
        queue.addOperation(nextOperation)
    }
    
    func cancel() {
        isCancelled = true
        
        queue.cancelAllOperations()

        guard let interface = interface, let task = sessionTask else {
            return
        }
        
        interface.cancel(task)
        sessionTask = nil
        self.data = nil
        image = nil
    }
}

extension BufferedImageView : NetworkSessionInterfaceDataTaskDelegate {
    
    func didReceive(response: URLResponse, for uuid:String?) {
        if isCancelled {
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            cancel()
            return
        }
        
        add { [weak self] in
            guard let sessionTask = self?.sessionTask, sessionTask.uuid == uuid, let defaultLength = self?.defaultContentLength else {
                return
            }
            
            var contentLength = Int(response.expectedContentLength)
            if contentLength < 0 {
                contentLength = defaultLength
            }
            
            self?.data = Data(capacity: contentLength)
        }
    }

    func didReceive(data: Data, for uuid:String?) throws {
        if isCancelled {
            return
        }
        
        add {
            [weak self] in
            guard let sessionTask = self?.sessionTask, sessionTask.uuid == uuid else {
                return
            }

            guard var storedData = self?.data else {
                return
            }
            
            storedData.append(data)
            
            let decoder = CCBufferedImageDecoder(data: storedData)
            decoder?.decompress()
            
            guard let decodedImage = decoder?.toImage() else {
                return
            }
            
            UIGraphicsBeginImageContext(CGSize(width: 1,height: 1))
            let context = UIGraphicsGetCurrentContext()
            context?.draw(decodedImage.cgImage!, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                if strongSelf.isCancelled {
                    return
                }
                
                strongSelf.image = decodedImage
            }
        }
    }
    
    func didFinish(uuid:String?) {
        guard let sessionTask = sessionTask, sessionTask.uuid == uuid else {
            return
        }
        
        add { [weak self] in
            self?.data = nil
        }
    }
    
    func didFail(uuid:String?, with error: URLError) {
        guard let sessionTask = sessionTask, let url = sessionTask.task.originalRequest?.url, let interface = interface  else {
            return
        }
        fallback(with:url, queue:queue.underlyingQueue ?? .main, interface:interface)
    }
}
