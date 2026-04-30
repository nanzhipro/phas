import SwiftUI

struct HomeRootView: View {
    let model: HomeScreenModel

    var body: some View {
        NavigationSplitView {
            List(model.sidebarSections, id: \.title) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.headline)
                    Text(section.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("phas")
            .frame(minWidth: 280)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    heroCard
                    HStack(alignment: .top, spacing: 20) {
                        summaryCard(
                            title: "Acceptance Target",
                            icon: "checkmark.seal",
                            lines: model.acceptanceTargets
                        )
                        summaryCard(
                            title: "Support Matrix",
                            icon: "cpu",
                            lines: model.supportMatrix
                        )
                    }
                    .frame(maxWidth: .infinity)

                    summaryCard(
                        title: "Phase-0 Deliverables",
                        icon: "shippingbox",
                        lines: model.phaseZeroDeliverables
                    )
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(model.subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
            Divider()
            Text(model.emptyStateMessage)
                .font(.body)
                .foregroundStyle(.primary)
            HStack(spacing: 12) {
                Button(model.primaryActionTitle) {
                }
                .buttonStyle(.borderedProminent)

                Button(model.secondaryActionTitle) {
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: .controlAccentColor).opacity(0.18),
                            Color(nsColor: .windowBackgroundColor)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func summaryCard(title: String, icon: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline)
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .padding(.top, 7)
                        .foregroundStyle(.secondary)
                    Text(line)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    HomeRootView(model: .default)
        .frame(width: 1200, height: 800)
}
