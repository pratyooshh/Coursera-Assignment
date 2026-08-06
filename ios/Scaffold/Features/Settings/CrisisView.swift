import SwiftUI

struct CrisisView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.stackGap) {
                Card(tint: Theme.coral) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "lifepreserver.fill")
                                .foregroundStyle(Theme.coral)
                            Text("You don't have to be in crisis to call")
                                .font(.headline)
                        }
                        Text(Crisis.message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ForEach(groupedResources, id: \.0) { region, resources in
                    Card(tint: Theme.coral) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(region)
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(.secondary)
                            ForEach(resources) { resource in
                                Button {
                                    open(resource)
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(resource.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            Text(resource.detail)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(resource.contact)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(Theme.coral)
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                DisclaimerNote(text: "Numbers change. If one doesn't connect, findahelpline.com lists verified services worldwide, or use your local emergency number.")
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Crisis support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var groupedResources: [(String, [CrisisResource])] {
        var order: [String] = []
        for r in Crisis.resources where !order.contains(r.region) {
            order.append(r.region)
        }
        return order.map { region in
            (region, Crisis.resources.filter { $0.region == region })
        }
    }

    private func open(_ resource: CrisisResource) {
        let contact = resource.contact
        if contact.contains(".") && !contact.contains(" ") {
            if let url = URL(string: "https://\(contact)") { openURL(url) }
            return
        }
        let digits = contact.filter { $0.isNumber }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
        openURL(url)
    }
}
