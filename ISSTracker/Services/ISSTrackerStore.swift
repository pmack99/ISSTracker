import Foundation
import SwiftData

@MainActor
@Observable
final class ISSTrackerStore {
    var position: ISSPosition?
    private(set) var motionPreviousPosition: ISSPosition?
    var passes: [ISSPass] = []
    var gallery: [NASAImageItem] = []
    var selectedGalleryIndex = 0

    var isLoadingPosition = false
    var isLoadingPasses = false
    var isLoadingGallery = false

    var positionError: String?
    var passesError: String?
    var galleryError: String?

    var issCrew: [SpaceTraveler] = []
    var isLoadingCrew = false
    var crewError: String?

    var cabinTelemetry = ISSCabinTelemetry.empty
    var cabinStatusMessage: String?

    var lastSearchLabel: String?
    var lastSearchLatitude: Double?
    var lastSearchLongitude: Double?

    private let api = ISSAPIService()
    private let cabinStream = ISSLiveCabinStreamService()
    private var refreshTask: Task<Void, Never>?

    func startLiveUpdates() {
        refreshTask?.cancel()
        cabinStream.onTelemetryChange = { [weak self] telemetry in
            self?.cabinTelemetry = telemetry
        }
        cabinStream.onStatusChange = { [weak self] message in
            self?.cabinStatusMessage = message
        }
        cabinStream.start()
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
        cabinStream.stop()
    }

    func refreshPosition() async {
        isLoadingPosition = position == nil
        positionError = nil
        do {
            let latest = try await api.fetchCurrentPosition()
            motionPreviousPosition = position
            position = latest
        } catch {
            positionError = error.localizedDescription
        }
        isLoadingPosition = false
    }

    func refreshCrew() async {
        isLoadingCrew = issCrew.isEmpty
        crewError = nil
        do {
            let response = try await api.fetchPeopleInSpace()
            issCrew = response.issCrew
        } catch {
            crewError = error.localizedDescription
        }
        isLoadingCrew = false
    }

    func searchPasses(
        placeName: String,
        latitude: Double,
        longitude: Double,
        modelContext: ModelContext,
        notificationService: PassNotificationService,
        saveToHistory: Bool = true
    ) async {
        isLoadingPasses = true
        passesError = nil
        passes = []
        lastSearchLabel = placeName
        lastSearchLatitude = latitude
        lastSearchLongitude = longitude

        do {
            let results = try await api.fetchVisualPasses(latitude: latitude, longitude: longitude)
            passes = results
            if saveToHistory {
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
            }
            if saveToHistory {
                await notificationService.schedulePasses(results, placeName: placeName)
            }
            WidgetPassSyncService.publish(passes: results, placeName: placeName)
            PassLiveActivityManager.sync(with: WidgetPassSyncService.snapshot(from: results, placeName: placeName))
        } catch ISSAPIError.noPasses {
            passesError = ISSAPIError.noPasses.localizedDescription
            notificationService.cancelScheduledPasses()
            WidgetPassSyncService.publish(snapshot: nil)
            PassLiveActivityManager.endAll()
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

    func refreshWidgetForPrimarySavedLocation(
        modelContext: ModelContext,
        notificationService: PassNotificationService
    ) async {
        let descriptor = FetchDescriptor<SavedLocation>(sortBy: [SortDescriptor(\SavedLocation.createdAt, order: .reverse)])
        guard let locations = try? modelContext.fetch(descriptor),
              let primary = locations.first(where: \.isWidgetPrimary)
        else { return }

        await searchPasses(
            placeName: primary.name,
            latitude: primary.latitude,
            longitude: primary.longitude,
            modelContext: modelContext,
            notificationService: notificationService,
            saveToHistory: false
        )
    }
}
