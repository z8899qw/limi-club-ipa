import UIKit
import WebKit

/// LIMI俱乐部 iOS 外壳。
/// 只做 Safari 做不到的事：全屏常驻、下载落地、外链跳转、离线提示。
/// 页面全部由服务器下发（/app 起），因此改功能不需要重装 APP。
final class ViewController: UIViewController {

    private enum C {
        static let start = "https://limi.xn--fiqs8s/app"
        static let alt = "http://43.132.194.67/app"
        static let ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 LIMIApp/1.0.1"
        static let bg = UIColor(red: 6.0 / 255.0, green: 10.0 / 255.0, blue: 18.0 / 255.0, alpha: 1)
        static let brand = UIColor(red: 0x60 / 255.0, green: 0x7B / 255.0, blue: 0xFE / 255.0, alpha: 1)
        static let text = UIColor(red: 0xE8 / 255.0, green: 0xF1 / 255.0, blue: 0xF8 / 255.0, alpha: 1)
        static let sub = UIColor(red: 0x8E / 255.0, green: 0xA3 / 255.0, blue: 0xBA / 255.0, alpha: 1)
    }

    private var web: WKWebView!
    private let bar = UIProgressView(progressViewStyle: .bar)
    private var errView: UIView!
    private var obs: NSKeyValueObservation?
    private var lastFile: URL?
    private var pendingDest: URL?

    // MARK: - 生命周期

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = C.bg

        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        cfg.websiteDataStore = .default()

        web = WKWebView(frame: .zero, configuration: cfg)
        web.customUserAgent = C.ua
        web.navigationDelegate = self
        web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = true
        web.isOpaque = false
        web.backgroundColor = C.bg
        web.scrollView.backgroundColor = C.bg
        web.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(web)

        bar.progressTintColor = C.brand
        bar.trackTintColor = .clear
        bar.isHidden = true
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)

        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            web.topAnchor.constraint(equalTo: g.topAnchor),
            web.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            web.bottomAnchor.constraint(equalTo: g.bottomAnchor),
            bar.topAnchor.constraint(equalTo: g.topAnchor),
            bar.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 2.0),
        ])

        buildErrorView()
        load(C.start)

        obs = web.observe(\.estimatedProgress, options: [.new]) { [weak self] wv, _ in
            guard let self = self else { return }
            let p = Float(wv.estimatedProgress)
            self.bar.setProgress(p, animated: false)
            self.bar.isHidden = (p >= 1.0)
        }
    }

    deinit {
        obs?.invalidate()
    }

    private func load(_ s: String) {
        guard let u = URL(string: s) else { return }
        bar.isHidden = false
        bar.setProgress(0, animated: false)
        web.load(URLRequest(url: u))
    }

    // MARK: - 错误页

    private func buildErrorView() {
        let box = UIView()
        box.backgroundColor = C.bg
        box.isHidden = true
        box.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(box)
        errView = box

        let title = UILabel()
        title.text = "连接不上服务器"
        title.textColor = C.text
        title.font = .systemFont(ofSize: 18, weight: .semibold)
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = "检查一下网络。如果一直连不上，多半是这台手机的 DNS 不认识这个域名，点下面第二个按钮走备用地址。"
        desc.textColor = C.sub
        desc.font = .systemFont(ofSize: 13)
        desc.numberOfLines = 0
        desc.textAlignment = .center

        let retry = UIButton(type: .system)
        retry.setTitle("重新加载", for: .normal)
        retry.setTitleColor(.white, for: .normal)
        retry.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        retry.backgroundColor = C.brand
        retry.layer.cornerRadius = 10
        retry.addTarget(self, action: #selector(onRetry), for: .touchUpInside)

        let alt = UIButton(type: .system)
        alt.setTitle("改用备用地址", for: .normal)
        alt.setTitleColor(C.brand, for: .normal)
        alt.titleLabel?.font = .systemFont(ofSize: 15)
        alt.layer.cornerRadius = 10
        alt.layer.borderWidth = 1
        alt.layer.borderColor = C.brand.withAlphaComponent(0.6).cgColor
        alt.addTarget(self, action: #selector(onAlt), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, desc, retry, alt])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.setCustomSpacing(6, after: title)
        stack.setCustomSpacing(22, after: desc)
        stack.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(stack)

        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            box.topAnchor.constraint(equalTo: g.topAnchor),
            box.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            box.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            box.bottomAnchor.constraint(equalTo: g.bottomAnchor),
            stack.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -30),
            retry.heightAnchor.constraint(equalToConstant: 46),
            alt.heightAnchor.constraint(equalToConstant: 46),
        ])
    }

    private func showError() {
        bar.isHidden = true
        bar.setProgress(0, animated: false)
        errView.isHidden = false
    }

    @objc private func onRetry() {
        errView.isHidden = true
        if let u = web.url { load(u.absoluteString) } else { load(C.start) }
    }

    @objc private func onAlt() {
        errView.isHidden = true
        load(C.alt)
    }

    // MARK: - 链接分流

    private func isInside(_ u: URL?) -> Bool {
        guard let h = u?.host?.lowercased() else { return false }
        return h == "limi.xn--fiqs8s" || h.hasSuffix(".limi.xn--fiqs8s")
            || h == "limi.中国" || h.hasSuffix(".limi.中国")
            || h == "43.132.194.67"
    }

    private func openOutside(_ u: URL) {
        UIApplication.shared.open(u, options: [:], completionHandler: nil)
    }

    // MARK: - 下载

    private func saveDestination(_ suggested: String) -> URL? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var name = suggested
        if name.isEmpty { name = "LIMI-download" }
        var target = dir.appendingPathComponent(name)
        var i = 2
        while FileManager.default.fileExists(atPath: target.path) {
            let base = (name as NSString).deletingPathExtension
            let ext = (name as NSString).pathExtension
            let next = ext.isEmpty ? "\(base)-\(i)" : "\(base)-\(i).\(ext)"
            target = dir.appendingPathComponent(next)
            i += 1
            if i > 200 { break }
        }
        return target
    }

    private func share(_ url: URL) {
        let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let p = ac.popoverPresentationController {
            p.sourceView = view
            p.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(ac, animated: true, completion: nil)
    }
}

// MARK: - WKNavigationDelegate

extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let u = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let s = u.scheme?.lowercased() ?? ""
        if s == "http" || s == "https" {
            if isInside(u) {
                decisionHandler(.allow)
            } else {
                openOutside(u)
                decisionHandler(.cancel)
            }
            return
        }
        if s == "about" || s == "file" || s == "data" || s == "blob" || s == "javascript" {
            decisionHandler(.allow)
            return
        }
        openOutside(u)
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }

    func webView(_ webView: WKWebView,
                 navigationResponse: WKNavigationResponse,
                 didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView,
                 navigationAction: WKNavigationAction,
                 didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        errView.isHidden = true
        bar.isHidden = true
    }

    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: Error) {
        showError()
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        showError()
    }
}

// MARK: - WKUIDelegate（必须实现，否则网页里的 alert / confirm / prompt 会静默失效）

extension ViewController: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "好", style: .default) { _ in completionHandler() })
        present(ac, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(false) })
        ac.addAction(UIAlertAction(title: "确定", style: .default) { _ in completionHandler(true) })
        present(ac, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let ac = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        ac.addTextField { tf in
            tf.text = defaultText
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
        }
        ac.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(nil) })
        ac.addAction(UIAlertAction(title: "确定", style: .default) { [weak ac] _ in
            completionHandler(ac?.textFields?.first?.text ?? "")
        })
        present(ac, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let u = navigationAction.request.url, !isInside(u) {
            openOutside(u)
        } else if let u = navigationAction.request.url {
            webView.load(URLRequest(url: u))
        }
        return nil
    }
}

// MARK: - WKDownloadDelegate

extension ViewController: WKDownloadDelegate {

    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        pendingDest = saveDestination(suggestedFilename)
        completionHandler(pendingDest)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let dest = pendingDest else {
            let ac = UIAlertController(title: "已下载",
                                       message: "文件已保存到「文件 → 我的 iPhone → LIMI」里。",
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
            present(ac, animated: true, completion: nil)
            return
        }
        lastFile = dest
        share(dest)
    }

    func download(_ download: WKDownload,
                  didFailWithError error: Error,
                  resumeData: Data?) {
        let ac = UIAlertController(title: "下载失败",
                                   message: error.localizedDescription,
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
        present(ac, animated: true, completion: nil)
    }
}
