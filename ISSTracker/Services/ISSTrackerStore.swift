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
    private var positionRefreshTask: Task<Void, Never>?
    private var cabinStreamActive = false
    private var isLiveTabVisible = false
    private var isSceneActive = false

    func setLiveTabVisible(_ visible: Bool) {
        isLiveTabVisible = visible
        reconcileCabinStream()
    }

    func setSceneActive(_ active: Bool) {
        isSceneActive = active
        reconcilePositionRefresh()
        reconcileCabinStream()
    }

    private func reconcilePositionRefresh() {
        if isSceneActive {
            startPositionRefreshIfNeeded()
        } else {
            stopPositionRefresh()
        }
    }

    private func startPositionRefreshIfNeeded() {
        guard positionRefreshTask == nil else { return }
        positionRefreshTask = Task {
            await refreshPosition()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { return }
                await refreshPosition()
            }
        }
    }

    private func stopPositionRefresh() {
        positionRefreshTask?.cancel()
        positionRefreshTask = nil
    }

    private func reconcileCabinStream() {
        let shouldRun = isLiveTabVisible && isSceneActive
        if shouldRun {
            startCabinStreamIfNeeded()
        } else {
            stopCabinStreamIfNeeded()
        }
    }

    private func startCabinStreamIfNeeded() {
        guard !cabinStreamActive else { return }
        cabinStreamActive = true
        cabinStream.onTelemetryChange = { [weak self] telemetry in
            self?.cabinTelemetry = telemetry
        }
        cabinStream.onStatusChange = { [weak self] message in
            self?.cabinStatusMessage = message
        }
        cabinStream.start()
    }

    private func stopCabinStreamIfNeeded() {
        guard cabinStreamActive else { return }
        cabinStreamActive = false
        cabinStream.stop()
    }

    func startLiveUpdates() {
        startCabinStreamIfNeeded()
    }

    func stopLiveUpdates() {
        stopCabinStreamIfNeeded()
    }

    func refreshPosition() async {
        isLoadingPosition = position == nil
        positionError = nil
        do {
            let latest = try await api.fetchCurrentPosition()
            motionPreviousPosition = position
            position = latest
        } catch {
            positionError = StoreErrorMessage.text(for: error)
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
            crewError = StoreErrorMessage.text(for: error)
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
                if let representative = Self.representativePass(from: results) {
                    let record = PassSearchRecord(
                        placeName: placeName,
                        passStart: representative.startDate,
                        durationSeconds: representative.duration,
                        appearsFrom: representative.startAzCompass,
                        departsTo: representative.endAzCompass,
                        maxElevation: representative.maxEl,
                        passCount: results.count
                    )
                    modelContext.insert(record)
                    try modelContext.save()
                }
                await notificationService.schedulePasses(results, placeName: placeName)
            }
            WidgetPassSyncService.publishFromSearch(passes: results, placeName: placeName)
        } catch ISSAPIError.noPasses {
            passesError = ISSAPIError.noPasses.localizedDescription
            notificationService.cancelScheduledPasses()
            WidgetPassSyncService.clearPassTrackingAndLiveActivity()
        } catch {
            passesError = StoreErrorMessage.text(for: error)
        }
        isLoadingPasses = false
    }

    private static func representativePass(from passes: [ISSPass]) -> ISSPass? {
        let now = Date()
        let sorted = passes.sorted { $0.startDate < $1.startDate }
        if let active = sorted.first(where: { now >= $0.startDate && now <= $0.endDate }) {
            return active
        }
        return sorted.first(where: { $0.startDate > now }) ?? sorted.first
    }

    func loadGallery() async {
        guard gallery.isEmpty else { return }
        isLoadingGallery = true
        galleryError = nil
        do {
            gallery = try await api.fetchISSImages()
            selectedGalleryIndex = Int.random(in: 0 ..< max(gallery.count, 1))
        } catch {
            galleryError = StoreErrorMessage.text(for: error)
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
