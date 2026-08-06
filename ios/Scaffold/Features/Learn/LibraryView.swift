import SwiftUI

struct LibraryView: View {
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.stackGap) {
                    if query.isEmpty {
                        ForEach(Library.byCategory, id: \.0) { category, articles in
                            Card(tint: Theme.violet) {
                                VStack(alignment: .leading, spacing: 4) {
                                    SectionHeading(title: category.rawValue, systemImage: category.symbol)
                                        .padding(.bottom, 4)
                                    ForEach(articles) { article in
                                        row(article)
                                    }
                                }
                            }
                        }
                    } else {
                        let results = Library.all.filter {
                            $0.title.localizedCaseInsensitiveContains(query)
                                || $0.subtitle.localizedCaseInsensitiveContains(query)
                        }
                        if results.isEmpty {
                            SoftEmptyState(
                                title: "Nothing matched",
                                message: "Try a broader word — \"time\", \"sleep\", \"start\".",
                                systemImage: "magnifyingglass"
                            )
                        } else {
                            Card(tint: Theme.violet) {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(results) { row($0) }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Learn")
            .searchable(text: $query, prompt: "Search")
        }
    }

    private func row(_ article: Article) -> some View {
        NavigationLink {
            ArticleView(article: article)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: article.symbol)
                    .font(.subheadline)
                    .foregroundStyle(Theme.violet)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(article.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Text(article.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text("\(article.readMinutes)m")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Article

struct ArticleView: View {
    let article: Article
    @State private var showingSources = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: article.symbol)
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.gradientCool)
                    Text(article.title)
                        .font(.largeTitle.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    Text(article.subtitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 4)

                ForEach(article.body) { block in
                    view(for: block)
                }

                Divider().padding(.vertical, 8)

                DisclaimerNote(text: "General information, not medical advice, and not specific to you. Anything here that sounds like your life is worth taking to a clinician rather than acting on alone.")

                Button {
                    withAnimation { showingSources.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showingSources ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                        Text("Where this comes from")
                            .font(.footnote.weight(.medium))
                    }
                    .foregroundStyle(Theme.violet)
                }

                if showingSources {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(article.sources, id: \.self) { source in
                            Text("· " + source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.leading, 4)
                }

                Spacer(minLength: 30)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func view(for block: Block) -> some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(.title3.bold())
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)

        case .paragraph(let text):
            Text(text)
                .font(.body)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

        case .bullets(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Theme.violet)
                            .frame(width: 5, height: 5)
                            .padding(.top, 8)
                        Text(item)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 2)

        case .callout(let text):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.amber)
                Text(text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Theme.amber.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        case .quote(let text, let attribution):
            VStack(alignment: .leading, spacing: 6) {
                Text(text)
                    .font(.body.italic())
                    .fixedSize(horizontal: false, vertical: true)
                Text("— " + attribution)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 14)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Theme.violet.opacity(0.5))
                    .frame(width: 3)
            }
        }
    }
}
