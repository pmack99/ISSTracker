import Foundation
import SwiftData

@MainActor
@Observable
final class ISSTrackerStore {
    var position: ISSPosition?
    var passes: [ISSPass] = []
    var gallery: [NASAImageItem] = []
    var selectedGalleryIndex = 0

    var isLoadingPosition = false
    var isLoadingPasses = false
    var isLoadingGallery = false

    var positionError: String?
    var passesError: String?
    var galleryError: String?

    var lastSearchLabel: String?

    private let api = ISSAPIService()
    private var refreshTask: Task<Void, Never>?

    func startLiveUpdates() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await refreshPosition()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    func stopLiveUpdates() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refreshPosition() async {
        isLoadingPosition = position == nil
        positionError = nil
        do {
            position = try await api.fetchCurrentPosition()
        } catch {
            positionError = error.localizedDescription
        }
        isLoadingPosition = false
    }

    func searchPasses(
        placeName: String,
        latitude: Double,
        longitude: Double,
        modelContext: ModelContext
    ) async {
        isLoadingPasses = true
        passesError = nil
        passes = []
        lastSearchLabel = placeName

        do {
            let results = try await api.fetchVisualPasses(latitude: latitude, longitude: longitude)
            passes = results
            for pass in results {
                let record = PassSearchRecord(
                    placeName: placeName,
                    passStart: pass.startDate,
                    durationSeconds: pass.duration,
                    appearsFrom: pass.startAzCompass,
                    departsTo: pass.endAzCompass,
                    maxElevation: pass.maxEl
                )
                modelContext.insert(record)
            }
            try modelContext.save()
        } catch ISSAPIError.noPasses {
            passesError = ISSAPIError.noPasses.localizedDescription
        } catch {
            passesError = error.localizedDescription
        }
        isLoadingPasses = false
    }

    func loadGallery() async {
        guard gallery.isEmpty else { return }
        isLoadingGallery = true
        galleryError = nil
        do {
            gallery = try await api.fetchISSImages()
            selectedGalleryIndex = Int.random(in: 0 ..< max(gallery.count, 1))
        } catch {
            galleryError = error.localizedDescription
        }
        isLoadingGallery = false
    }

    func showRandomGalleryImage() {
        guard !gallery.isEmpty else { return }
        selectedGalleryIndex = Int.random(in: 0 ..< gallery.count)
    }
}
