//
//  ViewController.swift
//  NSURLProtocol-Swift
//
//  Created by askerzhang on 10/10/16.
//  Copyright © 2016 AskerZhang. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIWebViewDelegate, WebViewProgressDelegate {
    fileprivate var webView: UIWebView!
    fileprivate var progressView: WebViewProgressView!
    fileprivate var progressProxy: WebViewProgress!
    
    // MARK: LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        webView = UIWebView(frame: self.view.bounds)
        self.view.addSubview(webView)
        
        //progressProxy = WebViewProgress()
        webView.delegate = self
        //progressProxy.webViewProxyDelegate = self
        //progressProxy.progressDelegate = self
        
        let progressBarHeight: CGFloat = 2.0
        let navigationBarBounds = self.navigationController!.navigationBar.bounds
        let barFrame = CGRect(x: 0, y: navigationBarBounds.size.height - progressBarHeight, width: navigationBarBounds.width, height: progressBarHeight)
        progressView = WebViewProgressView(frame: barFrame)
        progressView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
        URLProtocol.registerClass(MyProtocol.self)
        
        loadApple()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.navigationBar.addSubview(progressView)
    }
    
    deinit {
        URLProtocol.unregisterClass(MyProtocol.self)
    }
    
    // MARK: Private Method
    fileprivate func loadApple() {
        let request = URLRequest(url: URL(string: "http://apple.com")!)

        if let newRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest {
                MyProtocol.setProperty(true, forKey: "ReplaceURL", in: newRequest)
                self.webView.loadRequest((newRequest as NSURLRequest) as URLRequest)
            }
        }
    
    // MARK: - WebViewProgressDelegate
    func webViewProgress(_ webViewProgress: WebViewProgress, updateProgress progress: Float) {
        progressView.setProgress(progress, animated: true)
    }
}


