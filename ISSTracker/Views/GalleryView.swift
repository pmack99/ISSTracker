import SwiftUI

struct GalleryView: View {
    @Environment(ISSTrackerStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoadingGallery, store.gallery.isEmpty {
                    ISSLoadingView(message: "Loading NASA gallery…")
                } else if let item = currentItem {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            AsyncImage(url: item.imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                                case .failure:
                                    ISSErrorStateView(
                                        title: "Image unavailable",
                                        message: "This NASA asset could not be loaded.",
                                        systemImage: "photo",
                                        retry: { await reloadGallery() }
                                    )
                                    .frame(minHeight: 220)
                                default:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 240)
                                }
                            }

                            Text(item.title)
                                .font(.title3.weight(.semibold))

                            if !store.gallery.isEmpty {
                                Text("Image \(store.selectedGalleryIndex + 1) of \(store.gallery.count)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }

                            Text(item.description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }
                        .padding()
                    }
                } else {
                    ISSErrorStateView(
                        title: "No photos yet",
                        message: store.galleryError ?? "Pull down to load the NASA ISS archive.",
                        systemImage: "photo.on.rectangle.angled",
                        retryTitle: "Load Gallery",
                        retry: { await reloadGallery() }
                    )
                }
            }
            .navigationTitle("ISS Photos")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.showRandomGalleryImage()
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                    }
                    .disabled(store.gallery.isEmpty)
                }
            }
            .refreshable { await reloadGallery() }
            .task { await store.loadGallery() }
        }
        .tint(ISSTheme.accent)
    }

    private var currentItem: NASAImageItem? {
        guard !store.gallery.isEmpty else { return nil }
        let index = min(max(store.selectedGalleryIndex, 0), store.gallery.count - 1)
        return store.gallery[index]
    }

    private func reloadGallery() async {
        store.gallery = []
        await store.loadGallery()
    }
}

#Preview {
    GalleryView()
        .environment(ISSTrackerStore())
}
