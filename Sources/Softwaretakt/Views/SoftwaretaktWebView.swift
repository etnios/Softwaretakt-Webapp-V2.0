import SwiftUI
import WebKit

struct SoftwaretaktWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.black
        
        // Configure to allow media playback
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Load the HTML file from the bundle
        if let htmlPath = Bundle.main.path(forResource: "SoftwaretaktPreview", ofType: "html") {
            let url = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            // Fallback to loading from the web if the file isn't in the bundle
            if let url = URL(string: "https://raw.githubusercontent.com/etnios/Softwaretakt-webapp/main/SoftwaretaktPreview.html") {
                webView.load(URLRequest(url: url))
            }
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Updates can be handled here if needed
    }
}

struct SoftwaretaktWebView_Previews: PreviewProvider {
    static var previews: some View {
        SoftwaretaktWebView()
            .ignoresSafeArea()
    }
}
