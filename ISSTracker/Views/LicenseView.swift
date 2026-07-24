import SwiftUI

struct LicenseView: View {
    private let licenseText: String = {
        if let url = Bundle.main.url(forResource: "LICENSE", withExtension: nil),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return "The MIT License (MIT)\n\nCopyright (c) 2013-2018 Blackrock Digital LLC"
    }()

    var body: some View {
        ScrollView {
            Text(licenseText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("MIT License")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LicenseView()
    }
}
