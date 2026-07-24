import SwiftUI

struct GalleryView: View {
    @Environment(ISSTrackerStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoadingGallery {
                    ProgressView("Loading NASA gallery…")
                } else if let item = currentItem {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            AsyncImage(url: item.imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                case .failure:
                                    ContentUnavailableView("Image unavailable", systemImage: "photo")
                                default:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 200)
                                }
                            }

                            Text(item.title)
                                .font(.title3.weight(.semibold))

                            Text(item.description)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "No photos",
                        systemImage: "photo.on.rectangle",
                        description: Text(store.galleryError ?? "Pull to load the NASA ISS archive.")
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
