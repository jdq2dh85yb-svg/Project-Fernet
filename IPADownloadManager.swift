import SwiftUI
import Foundation

final class IPADownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {

    @Published var progress: Double = 0
    @Published var isDownloading = false
    @Published var downloadedFile: URL?
    @Published var status = "Ready"
    @Published var errorMessage: String?

    private var session: URLSession!
    private var downloadTask: URLSessionDownloadTask?

    override init() {
        super.init()

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60 * 60
        configuration.httpShouldSetCookies = true
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpCookieAcceptPolicy = .always

        session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }

    // MARK: - Start

    func startDownload(from address: String) {
        let trimmedAddress = address.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let inputURL = URL(string: trimmedAddress),
              inputURL.scheme?.lowercased() == "https",
              inputURL.host != nil else {
            setError("Please enter a valid HTTPS link.")
            return
        }

        downloadTask?.cancel()

        DispatchQueue.main.async {
            self.progress = 0
            self.downloadedFile = nil
            self.errorMessage = nil
            self.isDownloading = true
            self.status = "Preparing download..."
        }

        let finalURL = googleDriveDownloadURL(for: inputURL)
        startTask(url: finalURL)
    }

    // MARK: - Google Drive

    private func googleDriveDownloadURL(for inputURL: URL) -> URL {
        let host = inputURL.host?.lowercased() ?? ""

        // Keep Google user-content download URLs unchanged.
        // Rewriting these URLs can remove required parameters.
        if host == "drive.usercontent.google.com" ||
            host.hasSuffix(".googleusercontent.com") {
            return inputURL
        }

        guard host == "drive.google.com",
              let components = URLComponents(
                url: inputURL,
                resolvingAgainstBaseURL: false
              ),
              let id = googleDriveID(from: components, url: inputURL) else {
            return inputURL
        }

        var downloadComponents = URLComponents(
            string: "https://drive.usercontent.google.com/download"
        )!

        downloadComponents.queryItems = [
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "export", value: "download"),
            URLQueryItem(name: "authuser", value: "0")
        ]

        return downloadComponents.url ?? inputURL
    }

    private func googleDriveID(
        from components: URLComponents,
        url: URL
    ) -> String? {
        if let id = components.queryItems?.first(where: {
            $0.name == "id"
        })?.value, !id.isEmpty {
            return id
        }

        let parts = url.pathComponents

        if let index = parts.firstIndex(of: "d"),
           parts.indices.contains(index + 1) {
            return parts[index + 1]
        }

        return nil
    }

    // MARK: - Create task

    private func startTask(url: URL) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(
            "application/octet-stream,*/*",
            forHTTPHeaderField: "Accept"
        )

        let newTask = session.downloadTask(with: request)
        downloadTask = newTask

        DispatchQueue.main.async {
            self.status = "Connecting..."
        }

        newTask.resume()
    }

    // MARK: - Progress

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        DispatchQueue.main.async {
            self.status = "Downloading..."

            if totalBytesExpectedToWrite > 0 {
                self.progress = min(
                    max(
                        Double(totalBytesWritten) /
                        Double(totalBytesExpectedToWrite),
                        0
                    ),
                    1
                )
            }
        }
    }

    // MARK: - Download finished

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let response = downloadTask.response as? HTTPURLResponse else {
            finishWithError("The server returned an invalid response.")
            return
        }

        guard (200...299).contains(response.statusCode) else {
            finishWithError("Server error: HTTP \(response.statusCode)")
            return
        }

        do {
            let fileHandle = try FileHandle(forReadingFrom: location)
            let header = fileHandle.readData(ofLength: 4)
            try? fileHandle.close()

            let mimeType = response.mimeType?.lowercased() ?? ""

            // An IPA is a ZIP archive. Do not save an HTML page as an IPA.
            let isZipFile =
                header.count >= 2 &&
                header[header.startIndex] == 0x50 &&
                header[header.index(after: header.startIndex)] == 0x4B

            if mimeType.contains("text/html") || !isZipFile {
                finishWithError(
                    "The link did not return an IPA file. Google Drive may require confirmation, access permission, or the file may have reached its download limit."
                )
                return
            }

            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

            let folder = documents.appendingPathComponent(
                "IPA Downloads",
                isDirectory: true
            )

            try FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )

            let suggestedName =
                response.suggestedFilename ?? "Downloaded.ipa"

            let baseName = suggestedName
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "\\", with: "_")

            let finalName = baseName.lowercased().hasSuffix(".ipa")
                ? baseName
                : baseName + ".ipa"

            let destination = folder.appendingPathComponent(finalName)

            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }

            try FileManager.default.moveItem(
                at: location,
                to: destination
            )

            DispatchQueue.main.async {
                self.downloadedFile = destination
                self.progress = 1
                self.isDownloading = false
                self.status = "Download complete"
                self.errorMessage = nil
                self.downloadTask = nil
            }

        } catch {
            finishWithError(error.localizedDescription)
        }
    }

    // MARK: - Errors

    private func finishWithError(_ message: String) {
        DispatchQueue.main.async {
            self.isDownloading = false
            self.status = "Download failed"
            self.errorMessage = message
            self.downloadTask = nil
        }
    }

    private func setError(_ message: String) {
        DispatchQueue.main.async {
            self.isDownloading = false
            self.status = "Download failed"
            self.errorMessage = message
        }
    }

    // MARK: - Cancel

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil

        DispatchQueue.main.async {
            self.isDownloading = false
            self.status = "Cancelled"
        }
    }

    // MARK: - URLSession errors

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }

        let nsError = error as NSError

        if nsError.code == NSURLErrorCancelled {
            return
        }

        finishWithError(error.localizedDescription)
    }
}
