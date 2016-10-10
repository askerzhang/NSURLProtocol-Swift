//
//  SwiftWebViewProgress.swift
//  SwiftWebViewProgress
//
//  Created by Daichi Ichihara on 2014/12/03.
//  Copyright (c) 2014 MokuMokuCloud. All rights reserved.
//

import UIKit

public protocol WebViewProgressDelegate {
    func webViewProgress(_ webViewProgress: WebViewProgress, updateProgress progress: Float)
}

open class WebViewProgress: NSObject {

    open var progressDelegate: WebViewProgressDelegate?
    open var webViewProxyDelegate: UIWebViewDelegate?
    open var progress: Float = 0.0

    fileprivate var loadingCount: Int!
    fileprivate var maxLoadCount: Int!
    fileprivate var currentUrl: URL?
    fileprivate var interactive: Bool!

    fileprivate let InitialProgressValue: Float = 0.1
    fileprivate let InteractiveProgressValue: Float = 0.5
    fileprivate let FinalProgressValue: Float = 0.9
    fileprivate let completePRCURLPath = "/webviewprogressproxy/complete"

    // MARK: Initializer
    override public init() {
        super.init()
        maxLoadCount = 0
        loadingCount = 0
        interactive = false
    }

    // MARK: Private Method
    fileprivate func startProgress() {
        if progress < InitialProgressValue {
            setProgress(InitialProgressValue)
        }
    }

    fileprivate func incrementProgress() {
        var progress = self.progress
        let maxProgress = interactive == true ? FinalProgressValue : InteractiveProgressValue
        let remainPercent = Float(Float(loadingCount) / Float(maxLoadCount))
        let increment = (maxProgress - progress) * remainPercent
        progress += increment
        progress = fmin(progress, maxProgress)
        setProgress(progress)
    }

    fileprivate func completeProgress() {
        setProgress(1.0)
    }

    fileprivate func setProgress(_ progress: Float) {
        guard progress > self.progress || progress == 0 else {
            return
        }
        self.progress = progress
        progressDelegate?.webViewProgress(self, updateProgress: progress)
    }

    // MARK: Public Method
    open func reset() {
        maxLoadCount = 0
        loadingCount = 0
        interactive = false
        setProgress(0.0)
    }

}

extension WebViewProgress: UIWebViewDelegate {
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {
            return false
        }
        if url.path == completePRCURLPath {
            completeProgress()
            return false
        }

        var ret = true
        if webViewProxyDelegate!.responds(to: #selector(UIWebViewDelegate.webView(_:shouldStartLoadWith:navigationType:))) {
            ret = webViewProxyDelegate!.webView!(webView, shouldStartLoadWith: request, navigationType: navigationType)
        }

        var isFragmentJump = false
        if let fragmentURL = url.fragment {
            let nonFragmentURL = url.absoluteString.replacingOccurrences(of: "#"+fragmentURL, with: "")
            isFragmentJump = nonFragmentURL == webView.request!.url!.absoluteString
        }

        let isTopLevelNavigation = request.mainDocumentURL! == request.url
        let isHTTP = url.scheme == "http" || url.scheme == "https"
        if ret && !isFragmentJump && isHTTP && isTopLevelNavigation {
            currentUrl = request.url
            reset()
        }
        return ret
    }

    public func webViewDidStartLoad(_ webView: UIWebView) {
        if webViewProxyDelegate!.responds(to: #selector(UIWebViewDelegate.webViewDidStartLoad(_:))) {
            webViewProxyDelegate!.webViewDidStartLoad!(webView)
        }

        loadingCount = loadingCount + 1
        maxLoadCount = Int(fmax(Double(maxLoadCount), Double(loadingCount)))
        startProgress()
    }

    public func webViewDidFinishLoad(_ webView: UIWebView) {
        if webViewProxyDelegate!.responds(to: #selector(UIWebViewDelegate.webViewDidFinishLoad(_:))) {
            webViewProxyDelegate!.webViewDidFinishLoad!(webView)
        }

        loadingCount = loadingCount - 1
        incrementProgress()

        let readyState = webView.stringByEvaluatingJavaScript(from: "document.readyState")

        let interactive = readyState == "interactive"
        if interactive {
            self.interactive = true
            let waitForCompleteJS = "window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '\(webView.request?.mainDocumentURL?.scheme)://\(webView.request?.mainDocumentURL?.host)\(completePRCURLPath)'; document.body.appendChild(iframe);  }, false);"
            webView.stringByEvaluatingJavaScript(from: waitForCompleteJS)
        }

        let isNotRedirect: Bool
        if let currentUrl = currentUrl {
            isNotRedirect = currentUrl == webView.request?.mainDocumentURL
        } else {
            isNotRedirect = false
        }

        let complete = readyState == "complete"
        if complete && isNotRedirect {
            completeProgress()
        }
    }

    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        if webViewProxyDelegate!.responds(to: #selector(UIWebViewDelegate.webView(_:didFailLoadWithError:))) {
            webViewProxyDelegate!.webView!(webView, didFailLoadWithError: error)
        }

        loadingCount = loadingCount - 1
        incrementProgress()

        let readyState = webView.stringByEvaluatingJavaScript(from: "document.readyState")

        let interactive = readyState == "interactive"
        if interactive {
            self.interactive = true
            let waitForCompleteJS = "window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '\(webView.request?.mainDocumentURL?.scheme)://\(webView.request?.mainDocumentURL?.host)\(completePRCURLPath)'; document.body.appendChild(iframe);  }, false);"
            webView.stringByEvaluatingJavaScript(from: waitForCompleteJS)
        }

        let isNotRedirect: Bool
        if let currentUrl = currentUrl {
            isNotRedirect = currentUrl == webView.request?.mainDocumentURL
        } else {
            isNotRedirect = false
        }

        let complete = readyState == "complete"
        if complete && isNotRedirect {
            completeProgress()
        }
    }
}
