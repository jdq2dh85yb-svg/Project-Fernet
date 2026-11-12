import Foundation
import SwiftUI

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Console Log

@MainActor
final class ConsoleLog: ObservableObject {
    static let shared = ConsoleLog()

    enum Level {
        case info
        case warning
        case error
    }

    struct Line: Identifiable {
        let id = UUID()
        let date = Date()
        let level: Level
        let text: String
    }

    @Published private(set) var lines: [Line] = []

    private init() {
        lines = [
            Line(level: .info, text: "Console ready")
        ]
    }

    func log(_ text: String, _ level: Level = .info) {
        lines.append(
            Line(
                level: level,
                text: text
            )
        )

        if lines.count > 500 {
            lines.removeFirst(lines.count - 500)
        }
    }

    func clear() {
        lines.removeAll()
    }

    var exportText: String {
        lines
            .map { line in
                "[\(line.date.formatted(date: .omitted, time: .standard))] \(line.text)"
            }
            .joined(separator: "\n")
    }
}

// MARK: - Backend Manager

@MainActor
final class BackendManager: ObservableObject {

    static let shared = BackendManager()

    // MARK: Published state

    @Published private(set) var isOnline = false
    @Published private(set) var isChecking = false
    @Published private(set) var isBusy = false

    @Published private(set) var statusMessage = "Not connected"
    @Published private(set) var lastChecked: Date?

    @Published private(set) var serverName = "LawinServerV2"

    @Published private(set) var lastHTTPStatus: Int?

    // MARK: Internal state

    private let session: URLSession

    // Internal initializer.
    // This must not be private because the existing app creates
    // BackendManager with BackendManager().

    init() {
        let configuration = URLSessionConfiguration.default

        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 15

        session = URLSession(configuration: configuration)
    }

    // MARK: - URL Helpers

    static func endpoint(
        base: String,
        path: String
    ) -> URL? {

        var text = base.trimmed

        guard !text.isEmpty else {
            return nil
        }

        if !text.contains("://") {
            text = "https://" + text
        }

        while text.hasSuffix("/") {
            text.removeLast()
        }

        var cleanPath = path.trimmed

        if !cleanPath.isEmpty && !cleanPath.hasPrefix("/") {
            cleanPath = "/" + cleanPath
        }

        guard let url = URL(string: text + cleanPath),
              let host = url.host,
              !host.isEmpty else {
            return nil
        }

        return url
    }

    static func makeRequest(
        url: URL,
        method: String = "GET",
        token: String = "",
        timeout: TimeInterval = 10
    ) -> URLRequest {

        var request = URLRequest(url: url)

        request.httpMethod = method
        request.timeoutInterval = timeout

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        if method != "GET" {
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        let cleanToken = token.trimmed

        if !cleanToken.isEmpty {
            request.setValue(
                "Bearer \(cleanToken)",
                forHTTPHeaderField: "Authorization"
            )
        }

        return request
    }

    // MARK: - Backend Base URL

    private func normalizedBaseURL(
        from raw: String
    ) -> URL? {

        let trimmed = raw.trimmed

        guard !trimmed.isEmpty else {
            return nil
        }

        var value = trimmed

        if !value.contains("://") {
            value = "https://" + value
        }

        while value.hasSuffix("/") {
            value.removeLast()
        }

        guard let url = URL(string: value),
              let host = url.host,
              !host.isEmpty else {
            return nil
        }

        return url
    }

    // MARK: - LawinServerV2 Connection Test

    /*
     LawinServerV2 does not expose a generic /health endpoint.

     The Node.js server listens on port 8080 and loads its
     actual Fortnite endpoints from the routes/ directory.

     Therefore this method deliberately does NOT request /health.

     We currently use the configured backend root to determine
     whether the HTTP server itself is reachable.

     HTTP responses such as 401/403/404 still prove that a web
     server answered. They are therefore handled differently
     from a connection/network failure.
     */

    func checkBackend(
        urlString: String,
        token: String = ""
    ) async {

        let console = ConsoleLog.shared

        guard !isChecking else {
            return
        }

        let trimmedURL = urlString.trimmed

        guard !trimmedURL.isEmpty else {
            isOnline = false
            statusMessage = "Enter a backend URL first"
            lastHTTPStatus = nil

            console.log(
                "No backend URL configured",
                .warning
            )

            return
        }

        guard let baseURL = normalizedBaseURL(
            from: trimmedURL
        ) else {

            isOnline = false
            statusMessage = "Invalid backend URL"
            lastHTTPStatus = nil

            console.log(
                "Invalid backend URL: \(trimmedURL)",
                .error
            )

            return
        }

        isChecking = true
        isBusy = true

        statusMessage = "Connecting to LawinServer..."
        lastHTTPStatus = nil

        defer {
            isChecking = false
            isBusy = false
        }

        console.log(
            "Testing LawinServer at \(baseURL.absoluteString)"
        )

        let request = Self.makeRequest(
            url: baseURL,
            method: "GET",
            token: token,
            timeout: 10
        )

        do {

            let (_, response) = try await session.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {

                isOnline = false
                statusMessage = "Invalid server response"
                lastChecked = Date()

                console.log(
                    "Server returned a non-HTTP response",
                    .error
                )

                return
            }

            lastChecked = Date()
            lastHTTPStatus = httpResponse.statusCode

            let status = httpResponse.statusCode

            /*
             Any HTTP response means that the server was reachable.

             2xx = normal successful response
             3xx = reachable, redirect
             4xx = reachable, endpoint/authentication issue
             5xx = reachable, server-side error
             */

            if (200...299).contains(status) {

                isOnline = true
                serverName = "LawinServerV2"
                statusMessage = "LawinServer is online"

                console.log(
                    "LawinServer answered with HTTP \(status)"
                )

                return
            }

            if (300...399).contains(status) {

                isOnline = true
                serverName = "LawinServerV2"
                statusMessage = "LawinServer is reachable"

                console.log(
                    "LawinServer answered with redirect HTTP \(status)",
                    .warning
                )

                return
            }

            if (400...499).contains(status) {

                isOnline = true
                serverName = "LawinServerV2"

                if status == 401 {
                    statusMessage =
                        "LawinServer reachable — authentication required"
                } else if status == 403 {
                    statusMessage =
                        "LawinServer reachable — access forbidden"
                } else if status == 404 {
                    statusMessage =
                        "LawinServer reachable — endpoint not found"
                } else {
                    statusMessage =
                        "LawinServer reachable — HTTP \(status)"
                }

                console.log(
                    "LawinServer is reachable. HTTP \(status)",
                    .warning
                )

                return
            }

            if (500...599).contains(status) {

                isOnline = true
                serverName = "LawinServerV2"
                statusMessage =
                    "LawinServer reachable — server error HTTP \(status)"

                console.log(
                    "LawinServer answered with HTTP \(status)",
                    .error
                )

                return
            }

            isOnline = false
            statusMessage = "Unexpected HTTP \(status)"

            console.log(
                "Unexpected HTTP status \(status)",
                .warning
            )

        } catch {

            isOnline = false
            lastChecked = Date()
            lastHTTPStatus = nil

            statusMessage = readableError(
                error
            )

            console.log(
                "LawinServer connection failed: \(statusMessage)",
                .error
            )
        }
    }

    // MARK: - Error handling

    private func readableError(
        _ error: Error
    ) -> String {

        if let urlError = error as? URLError {

            switch urlError.code {

            case .notConnectedToInternet:
                return "No internet connection"

            case .networkConnectionLost:
                return "Network connection lost"

            case .timedOut:
                return "Connection timed out"

            case .cannotFindHost:
                return "Could not find backend host"

            case .cannotConnectToHost:
                return "Could not connect to backend"

            case .dnsLookupFailed:
                return "DNS lookup failed"

            case .secureConnectionFailed:
                return "Secure HTTPS connection failed"

            case .appTransportSecurityRequiresSecureConnection:
                return "iOS requires HTTPS for this connection"

            case .badURL:
                return "Invalid backend URL"

            case .cancelled:
                return "Connection check cancelled"

            default:
                return urlError.localizedDescription
            }
        }

        return error.localizedDescription
    }

    // MARK: - Generic GET

    func get(
        path: String,
        settings: AppSettings
    ) async throws -> (Data, HTTPURLResponse) {

        guard let url = Self.endpoint(
            base: settings.backendURL,
            path: path
        ) else {
            throw BackendError.invalidURL
        }

        let request = Self.makeRequest(
            url: url,
            method: "GET",
            token: settings.apiToken,
            timeout: 10
        )

        ConsoleLog.shared.log(
            "GET \(url.absoluteString)"
        )

        let result = try await session.data(
            for: request
        )

        guard let response = result.1 as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        return (
            result.0,
            response
        )
    }

    // MARK: - Generic POST

    func post(
        path: String,
        settings: AppSettings,
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {

        guard let url = Self.endpoint(
            base: settings.backendURL,
            path: path
        ) else {
            throw BackendError.invalidURL
        }

        var request = Self.makeRequest(
            url: url,
            method: "POST",
            token: settings.apiToken,
            timeout: 15
        )

        if let body {
            request.httpBody = body
        }

        ConsoleLog.shared.log(
            "POST \(url.absoluteString)"
        )

        let result = try await session.data(
            for: request
        )

        guard let response = result.1 as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        return (
            result.0,
            response
        )
    }

    // MARK: - Server Control

    /*
     These remain available for the existing UI, but LawinServerV2
     itself does not use our old generic start/stop endpoints.

     We therefore only call them when the user has explicitly
     configured an endpoint in AppSettings.
     */

    func start(
        settings: AppSettings
    ) async {

        await control(
            verb: "start",
            path: settings.startPath,
            settings: settings
        )
    }

    func stop(
        settings: AppSettings
    ) async {

        await control(
            verb: "stop",
            path: settings.stopPath,
            settings: settings
        )
    }

    private func control(
        verb: String,
        path: String,
        settings: AppSettings
    ) async {

        guard !isBusy else {
            return
        }

        let console = ConsoleLog.shared

        guard !settings.backendURL.trimmed.isEmpty else {
            statusMessage = "Enter a backend URL first"

            console.log(
                "Cannot \(verb): no backend URL configured",
                .warning
            )

            return
        }

        guard !path.trimmed.isEmpty else {
            statusMessage =
                "No \(verb) endpoint configured"

            console.log(
                "\(verb.capitalized) is unavailable: no endpoint configured",
                .warning
            )

            return
        }

        guard let url = Self.endpoint(
            base: settings.backendURL,
            path: path
        ) else {

            statusMessage =
                "Invalid \(verb) endpoint"

            console.log(
                "Invalid \(verb) endpoint",
                .error
            )

            return
        }

        isBusy = true

        defer {
            isBusy = false
        }

        statusMessage =
            verb == "start"
            ? "Starting..."
            : "Stopping..."

        console.log(
            "POST \(url.absoluteString)"
        )

        do {

            let request = Self.makeRequest(
                url: url,
                method: "POST",
                token: settings.apiToken,
                timeout: 15
            )

            let (_, response) = try await session.data(
                for: request
            )

            guard let http = response as? HTTPURLResponse else {
                throw BackendError.invalidResponse
            }

            lastHTTPStatus = http.statusCode

            guard (200...299).contains(
                http.statusCode
            ) else {

                statusMessage =
                    "\(verb.capitalized) failed — HTTP \(http.statusCode)"

                console.log(
                    statusMessage,
                    .error
                )

                return
            }

            console.log(
                "\(verb.capitalized) request accepted — HTTP \(http.statusCode)"
            )

            if verb == "start" {

                await checkBackend(
                    urlString: settings.backendURL,
                    token: settings.apiToken
                )

            } else {

                isOnline = false
                lastChecked = Date()
                statusMessage = "Backend stopped"

                console.log(
                    "Backend stopped"
                )
            }

        } catch {

            statusMessage = readableError(
                error
            )

            console.log(
                "\(verb.capitalized) failed: \(statusMessage)",
                .error
            )
        }
    }

    // MARK: - Disconnect

    func disconnect() {

        isOnline = false
        isChecking = false
        isBusy = false

        lastHTTPStatus = nil

        statusMessage = "Disconnected"

        ConsoleLog.shared.log(
            "Disconnected from backend"
        )
    }
}

// MARK: - Backend Errors

enum BackendError: LocalizedError {

    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case serverError(Int)

    var errorDescription: String? {

        switch self {

        case .invalidURL:
            return "Invalid backend URL"

        case .invalidResponse:
            return "Invalid server response"

        case .unauthorized:
            return "Authentication required"

        case .forbidden:
            return "Access forbidden"

        case .serverError(let status):
            return "Server returned HTTP \(status)"
        }
    }
}
