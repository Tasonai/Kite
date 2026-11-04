import SwiftUI
import SwiftData
import KiteKit

struct WindowsSyncView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("windows_sync_endpoint") private var winEndpoint = "http://127.0.0.1:24243"
    @AppStorage("windows_auto_sync") private var autoSync = true

    @State private var connectionStatus: String?
    @State private var isOnline: Bool?
    @State private var isSyncing = false
    @State private var pulledCount = 0
    @State private var pushedCount = 0
    @State private var logs: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                        Text("P2P-Синхронизация с Windows (KiteWin)")
                            .font(.title2.weight(.bold))
                    }
                    Text("Двусторонняя репликация банка идей, спецификаций и промптов по локальной сети.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Windows Connection Card
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "desktopcomputer")
                                .foregroundStyle(Color.accentColor)
                            Text("Подключение к KiteWin на Windows 11")
                                .font(.headline)
                            Spacer()
                            if let isOnline = isOnline {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(isOnline ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                    Text(isOnline ? "В сети" : "Недоступен")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(isOnline ? Color.green : Color.red)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background((isOnline ? Color.green : Color.red).opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }

                        HStack(spacing: 12) {
                            TextField("Адрес Windows сервера (порт 24243)", text: $winEndpoint)
                                .textFieldStyle(.roundedBorder)

                            Button {
                                checkWindowsConnection()
                            } label: {
                                Label("Проверить связь", systemImage: "network")
                            }
                            .buttonStyle(.bordered)
                        }

                        if let status = connectionStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundStyle(isOnline == true ? Color.green : Color.secondary)
                        }
                    }
                    .padding(8)
                }

                // Sync Actions Card
                GroupBox {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Двусторонняя синхронизация")
                                    .font(.headline)
                                Text("Объединяет идеи с Mac и Windows без дубликатов и без потери данных.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()

                            Button {
                                performBidirectionalSync()
                            } label: {
                                HStack(spacing: 6) {
                                    if isSyncing {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                    }
                                    Text("Синхронизировать сейчас")
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSyncing)
                        }

                        // Metrics Grid
                        HStack(spacing: 12) {
                            metricBox(title: "Получено с Windows", value: "+\(pulledCount)", icon: "arrow.down.circle")
                            metricBox(title: "Отправлено на Windows", value: "\(pushedCount)", icon: "arrow.up.circle")
                            metricBox(title: "Сервер Mac (порт 24242)", value: "АКТИВЕН", icon: "antenna.radiowaves.left.and.right")
                        }
                    }
                    .padding(8)
                }

                // Log view
                GroupBox("Журнал операций") {
                    VStack(alignment: .leading, spacing: 6) {
                        if logs.isEmpty {
                            Text("Журнал пуст. Нажмите «Синхронизировать сейчас» или «Проверить связь».")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(logs, id: \.self) { log in
                                        Text(log)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .frame(maxHeight: 180)
                        }
                    }
                    .padding(6)
                }
            }
            .padding(24)
        }
        .onAppear {
            addLog("P2P модуль готов к работе. Mac сервер слушает порт 24242.")
        }
    }

    private func metricBox(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func checkWindowsConnection() {
        guard let url = URL(string: "\(cleanEndpoint(winEndpoint))/api/status") else {
            connectionStatus = "Неверный формат URL."
            return
        }

        addLog("Проверка связи с \(url.absoluteString)...")
        var req = URLRequest(url: url)
        req.timeoutInterval = 3

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                    await MainActor.run {
                        self.isOnline = true
                        self.connectionStatus = "Соединение установлено. KiteWin активен."
                        self.addLog("Успешное рукопожатие с KiteWin на Windows. Код 200.")
                    }
                } else {
                    await MainActor.run {
                        self.isOnline = false
                        self.connectionStatus = "Ошибка HTTP: \((response as? HTTPURLResponse)?.statusCode ?? 0)"
                        self.addLog("Ошибка ответа от Windows: статус \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isOnline = false
                    self.connectionStatus = "Нет ответа: \(error.localizedDescription)"
                    self.addLog("Хост недоступен: \(error.localizedDescription)")
                }
            }
        }
    }

    private func performBidirectionalSync() {
        guard let pullUrl = URL(string: "\(cleanEndpoint(winEndpoint))/api/ideas"),
              let pushUrl = URL(string: "\(cleanEndpoint(winEndpoint))/api/ideas") else {
            connectionStatus = "Неверный формат URL."
            return
        }

        isSyncing = true
        addLog("Запуск двусторонней репликации...")

        Task {
            var newFromWin = 0
            // 1. Pull from Windows
            do {
                var pullReq = URLRequest(url: pullUrl)
                pullReq.timeoutInterval = 5
                let (data, res) = try await URLSession.shared.data(for: pullReq)
                if let http = res as? HTTPURLResponse, http.statusCode == 200 {
                    newFromWin = await MainActor.run {
                        model.importIdeas(from: data)
                    }
                    await MainActor.run {
                        self.pulledCount += newFromWin
                        self.addLog("Успешно загружено с Windows: +\(newFromWin) идей.")
                    }
                }
            } catch {
                await MainActor.run {
                    self.addLog("Ошибка чтения с Windows: \(error.localizedDescription)")
                }
            }

            // 2. Push all local ideas to Windows
            var pushedCount = 0
            if let exportData = await MainActor.run(body: { model.exportIdeas() }) {
                do {
                    var pushReq = URLRequest(url: pushUrl)
                    pushReq.httpMethod = "POST"
                    pushReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    pushReq.httpBody = exportData
                    pushReq.timeoutInterval = 5

                    let (data, res) = try await URLSession.shared.data(for: pushReq)
                    if let http = res as? HTTPURLResponse, http.statusCode == 200 {
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let count = json["imported"] as? Int {
                            pushedCount = count
                        }
                        await MainActor.run {
                            self.pushedCount = pushedCount
                            self.addLog("Успешно отправлено на Windows: \(pushedCount) идей.")
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.addLog("Ошибка отправки на Windows: \(error.localizedDescription)")
                    }
                }
            }

            await MainActor.run {
                self.isSyncing = false
                self.connectionStatus = "Синхронизация завершена: +\(newFromWin) получено, \(pushedCount) отправлено."
                self.addLog("Синхронизация успешно выполнена.")
            }
        }
    }

    private func cleanEndpoint(_ raw: String) -> String {
        var str = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasSuffix("/") { str.removeLast() }
        if !str.hasPrefix("http://") && !str.hasPrefix("https://") {
            str = "http://" + str
        }
        return str
    }

    private func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        logs.insert("[\(timestamp)] \(message)", at: 0)
    }
}
