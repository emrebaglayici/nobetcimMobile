import SwiftUI

struct LegalSection: Identifiable {
    let id: String
    let heading: String
    let paragraphs: [String]
    let bullets: [String]

    init(heading: String, paragraphs: [String] = [], bullets: [String] = []) {
        id = heading
        self.heading = heading
        self.paragraphs = paragraphs
        self.bullets = bullets
    }
}

struct LegalTextView: View {
    let title: String
    let lastUpdated: String?
    let sections: [LegalSection]
    let footer: String?

    init(
        title: String,
        lastUpdated: String? = nil,
        sections: [LegalSection],
        footer: String? = "Bu metin genel bilgilendirme amaçlıdır; hukuki danışmanlık yerine geçmez."
    ) {
        self.title = title
        self.lastUpdated = lastUpdated
        self.sections = sections
        self.footer = footer
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let lastUpdated {
                    Text(lastUpdated)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.heading)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        ForEach(section.paragraphs, id: \.self) { paragraph in
                            Text(paragraph)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !section.bullets.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(section.bullets, id: \.self) { bullet in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                        Text(bullet)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .font(.body)
                                }
                            }
                        }
                    }
                }

                if let footer {
                    Text(footer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
