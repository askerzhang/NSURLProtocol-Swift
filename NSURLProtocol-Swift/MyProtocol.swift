//
//  MyProtocol.swift
//  SwiftWebViewProgress
//
//  Created by askerzhang on 10/10/16.
//  Copyright © 2016 AskerZhang. All rights reserved.

import Foundation

class MyProtocol: URLProtocol, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    static let strKeyForNewsURL = "ReplaceURL"
    
    var session: URLSession?
    var downloadTask: URLSessionDataTask?
    var mutableData: NSMutableData?
    var response: URLResponse?
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard request.httpMethod != "Get" else{
            return false
        }
        
        guard request.url != nil else {return false}
        
        if MyProtocol.property(forKey: strKeyForNewsURL, in: request) == nil {
            return false
        }
        
        let useMyProtocol = MyProtocol.property(forKey: "IsProtocolApplied", in: request) == nil
        
        return useMyProtocol
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(_ aRequest: URLRequest,
                                                 to bRequest: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(aRequest, to:bRequest)
    }
    
    override func startLoading() {
        
        if let newRequest = (self.request as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
            MyProtocol.setProperty(true, forKey: "IsProtocolApplied", in: newRequest)
            if !self.newsCacheResponse(request: self.request) {
                self.runSelfRequest()
            }
        }
    }
    
    override func stopLoading() {
        self.session?.invalidateAndCancel()
        self.session = nil
        self.response = nil
        self.mutableData = nil
        self.downloadTask = nil
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        
        if let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
            MyProtocol.setProperty(true, forKey: "IsProtocolApplied", in: mutableRequest)
            self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.client?.urlProtocol(self, didLoad: data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        let error = error ?? NSError(domain: NSUnderlyingErrorKey, code: 0, userInfo: nil)
        self.client?.urlProtocol(self, didFailWithError: error)
    }
    
    func cacheUrlOfRequest(request: URLRequest) -> String? {
        return MyProtocol.property(forKey: "ReplaceURL", in: request) as? String
    }
    
    func newsCacheResponse(request: URLRequest) -> Bool {
        
        guard (request.url?.absoluteURL) != nil else { return false}

        let strUrl = "http://www.amazon.com"
        guard let testUrl = URL(string: strUrl) else {return false}
    
        let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 9_3_1 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4"
        
        let session = URLSession.shared;
 
        var request = URLRequest(url: testUrl)
        request.httpMethod = "Get"
        request.addValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let task = session.dataTask(with: request) { [weak self](data, urlResponse, error) in
            guard let strongSelf = self else { return}
            guard let data = data else {return}
            
            //var realResponse = data(using: String.Encoding.utf8)
            let dataHtml = String.init(data: data, encoding: String.Encoding.utf8)
            
            guard let strHtml = dataHtml else { return}

            let cacheHtml = strHtml.replacingOccurrences(of: "</head>", with: "<!--Replaced HTML--></head>")
            let realResponse = cacheHtml.data(using: String.Encoding.utf8)
        
            guard let cacheResponse = realResponse else {
                strongSelf.runSelfRequest()
                return
            }
            
            let myResponse = URLResponse.init(url: testUrl, mimeType: "text/html", expectedContentLength: cacheResponse.count, textEncodingName: "utf-8")
            strongSelf.client?.urlProtocol(strongSelf, didReceive: myResponse, cacheStoragePolicy: URLCache.StoragePolicy.notAllowed)
            strongSelf.client?.urlProtocol(strongSelf, didLoad: cacheResponse)
            strongSelf.client?.urlProtocolDidFinishLoading(strongSelf)
        }
        task.resume()
        
        return true
    }
    
    private func runSelfRequest() -> Void {
        let config = URLSessionConfiguration.default
        let operationQueue = OperationQueue.current
        // swiftlint:disable:next custom_rules
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)
        self.downloadTask = self.session?.dataTask(with: self.request)
        self.downloadTask?.resume()
    }
    
}

