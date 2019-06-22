//
//  RTRSOperation.swift
//  RTRS
//
//  Created by Jonathan Chen on 4/19/19.
//  Copyright © 2019 Jonathan Chen. All rights reserved.
//

import Foundation
import WebKit

class RTRSOperation: Operation, WKUIDelegate {
    
    let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    let url: URL!
    let pageName: String!
    
    fileprivate let getDomScript = """
    Element.prototype.serializeWithStyles = (function () {
    
    // Mapping between tag names and css default values lookup tables. This allows to exclude default values in the result.
    var defaultStylesByTagName = {};
    
    // Styles inherited from style sheets will not be rendered for elements with these tag names
    var noStyleTags = {"BASE":true,"HEAD":true,"HTML":true,"META":true,"NOFRAME":true,"NOSCRIPT":true,"PARAM":true,"SCRIPT":true,"STYLE":true,"TITLE":true};
    
    // This list determines which css default values lookup tables are precomputed at load time
    // Lookup tables for other tag names will be automatically built at runtime if needed
    var tagNames = ["A","ABBR","ADDRESS","AREA","ARTICLE","ASIDE","AUDIO","B","BASE","BDI","BDO","BLOCKQUOTE","BODY","BR","BUTTON","CANVAS","CAPTION","CENTER","CITE","CODE","COL","COLGROUP","COMMAND","DATALIST","DD","DEL","DETAILS","DFN","DIV","DL","DT","EM","EMBED","FIELDSET","FIGCAPTION","FIGURE","FONT","FOOTER","FORM","H1","H2","H3","H4","H5","H6","HEAD","HEADER","HGROUP","HR","HTML","I","IFRAME","IMG","INPUT","INS","KBD","KEYGEN","LABEL","LEGEND","LI","LINK","MAP","MARK","MATH","MENU","META","METER","NAV","NOBR","NOSCRIPT","OBJECT","OL","OPTION","OPTGROUP","OUTPUT","P","PARAM","PRE","PROGRESS","Q","RP","RT","RUBY","S","SAMP","SCRIPT","SECTION","SELECT","SMALL","SOURCE","SPAN","STRONG","STYLE","SUB","SUMMARY","SUP","SVG","TABLE","TBODY","TD","TEXTAREA","TFOOT","TH","THEAD","TIME","TITLE","TR","TRACK","U","UL","VAR","VIDEO","WBR"];
    
    // Precompute the lookup tables.
    for (var i = 0; i < tagNames.length; i++) {
    if(!noStyleTags[tagNames[i]]) {
    defaultStylesByTagName[tagNames[i]] = computeDefaultStyleByTagName(tagNames[i]);
    }
    }
    
    function computeDefaultStyleByTagName(tagName) {
    var defaultStyle = {};
    var element = document.body.appendChild(document.createElement(tagName));
    var computedStyle = getComputedStyle(element);
    for (var i = 0; i < computedStyle.length; i++) {
    defaultStyle[computedStyle[i]] = computedStyle[computedStyle[i]];
    }
    document.body.removeChild(element);
    return defaultStyle;
    }
    
    function getDefaultStyleByTagName(tagName) {
    tagName = tagName.toUpperCase();
    if (!defaultStylesByTagName[tagName]) {
    defaultStylesByTagName[tagName] = computeDefaultStyleByTagName(tagName);
    }
    return defaultStylesByTagName[tagName];
    }
    
    return function serializeWithStyles() {
    if (this.nodeType !== Node.ELEMENT_NODE) { throw new TypeError(); }
    var cssTexts = [];
    var elements = this.querySelectorAll("*");
    for ( var i = 0; i < elements.length; i++ ) {
    var e = elements[i];
//    if (!noStyleTags[e.tagName]) {
    var computedStyle = getComputedStyle(e);
    var defaultStyle = getDefaultStyleByTagName(e.tagName);
    cssTexts[i] = e.style.cssText;
    for (var ii = 0; ii < computedStyle.length; ii++) {
    var cssPropName = computedStyle[ii];
    if (computedStyle[cssPropName] !== defaultStyle[cssPropName]) {
    e.style[cssPropName] = computedStyle[cssPropName];
    }
    }
    }
    }
    var result = this.outerHTML;
    for ( var i = 0; i < elements.length; i++ ) {
    elements[i].style.cssText = cssTexts[i];
    }
    return result;
    }
    })();
    document.body.serializeWithStyles()
"""
    
    required init(url: URL, pageName: String) {
        self.url = url
        self.pageName = pageName
        super.init()
    }
    
    override func start() {
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        let request = URLRequest(url: URL(string: "\(self.url.absoluteString)?format=json-pretty")!)
        let task = urlSession.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let data = data,
                let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
                let collectionDict = dict["collection"] as? [String: Any], let updated = collectionDict["updatedOn"] as? Int {
                
                let lastUpdate = UserDefaults.standard.integer(forKey: "\(self.pageName!)-\(RTRSUserDefaultsKeys.lastUpdated)")
                if updated > lastUpdate {
                    UserDefaults.standard.set(updated, forKey: RTRSUserDefaultsKeys.lastUpdated)
                    let myRequest = URLRequest(url: self.url)
                    self.webView.load(myRequest)
                } else {
                    
                }
            }
        }
        task.resume()

    }
}

extension RTRSOperation: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript(getDomScript,
                                   completionHandler: { (html: Any?, error: Error?) in
                                    guard let theHtml = html as? String else { return }
                                    
                                    UserDefaults.standard.set(theHtml, forKey: "\(self.pageName!)-\(RTRSUserDefaultsKeys.htmlStorage)")
                                    self.completionBlock?()
        })
    }
    
}
