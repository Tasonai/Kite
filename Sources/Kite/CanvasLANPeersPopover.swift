import SwiftUI
import KiteKit

struct CanvasLANPeersPopover: View {
    let peers: [KitePeer]
    let onSync: (KitePeer) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .foregroundStyle(Color.accentColor)
                Text("Устройства в локальной сети")
                    .font(.headline)
                Spacer()
                Text("\(peers.count)")
                    .font(.system(size: 10, design: .monospaced)) // grid: ok font
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }

            Divider()

            if peers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Поиск инстансов Kite в сети...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Запустите Kite на Windows или другом Mac для авто-обнаружения")
                        .font(.system(size: 10)) // grid: ok font
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(peers) { peer in
                        HStack(spacing: 8) {
                            Image(systemName: peer.platform.contains("Windows") ? "laptopcomputer" : "desktopcomputer")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(peer.hostname)
                                    .font(.subheadline.bold())
                                Text("\(peer.platform) - \(peer.ip):\(peer.port)")
                                    .font(.system(size: 10, design: .monospaced)) // grid: ok font
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Синхронизировать") {
                                onSync(peer)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 380)
    }
}
