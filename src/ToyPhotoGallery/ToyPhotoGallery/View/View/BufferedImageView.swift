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

    /// Initialize a new image view and start loading a JPEG from the given URL
    init(url: Foundation.URL, networkSessionInterface:NetworkSessionInterface?) {
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
    
    /// Load a JPEG from the given URL
    func load(_ url: Foundation.URL, with interface:NetworkSessionInterface, session:URLSession) {
        if isCancelled {
            return
        }
        
        image = nil
        sessionTask = interface.downloadFile(from: url, with: session, retain: false, dataDelegate:self)
    }
}

extension BufferedImageView {
    // We need this to use the same OperationQueue as out network, AND we need these operations to
    // happen in order pseudo-serially
    func add(interface:NetworkSessionInterface, operation:@escaping ()->Void) {
        let nextOperation = BlockOperation {
            DispatchQueue.global().sync {
                operation()
            }
        }
        
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
    func didReceive(data: Data, for uuid:String?) throws {
        if isCancelled {
            return
        }
        guard let sessionTask = sessionTask, sessionTask.uuid == uuid, let interface = interface else {
            return
        }
        
        add(interface: interface) { [weak self] in
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
    
    func didReceive(response: URLResponse, for uuid:String?) {
        if isCancelled {
            return
        }

        guard let sessionTask = sessionTask, sessionTask.uuid == uuid, let interface = interface else {
            return
        }
        var contentLength = Int(response.expectedContentLength)
        if contentLength < 0 {
            contentLength = defaultContentLength
        }
        
        add(interface: interface) { [weak self] in
            self?.data = Data(capacity: contentLength)
        }
    }
    
    func didFinish(uuid:String?) {
        guard let sessionTask = sessionTask, sessionTask.uuid == uuid, let interface = interface else {
            return
        }
        
        add(interface: interface) { [weak self] in
            self?.data = nil
        }
    }
    
    func didFail(uuid:String?, with error: URLError) {
        guard let interface = interface, let session = interface.session, let sessionTask = sessionTask, let url = sessionTask.task.originalRequest?.url  else {
            return
        }
        
        session.dataTask(with: url) { [weak self] (data, response, error) in
            if let e = error as? URLError {
                switch e {
                case URLError.cancelled:
                    print("Again!")
                default:
                    interface.errorHandler.report(e)
                }
                return
            }
            
            guard let data = data else {
                return
            }
            
            if let fetchedImage = UIImage(data: data) {
                self?.image = fetchedImage
            }
        }
    }
}
