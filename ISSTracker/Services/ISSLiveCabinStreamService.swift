import Foundation
import LightstreamerClientCompact

@MainActor
final class ISSLiveCabinStreamService {
    private let client: LightstreamerClient
    private let subscription: Subscription
    private let delegateBridge: CabinSubscriptionDelegate
    private var isRunning = false

    var onTelemetryChange: ((ISSCabinTelemetry) -> Void)?
    var onStatusChange: ((String?) -> Void)?

    private(set) var telemetry = ISSCabinTelemetry.empty

    init() {
        client = LightstreamerClient(serverAddress: "https://push.lightstreamer.com/", adapterSet: "ISSLIVE")
        subscription = Subscription(
            subscriptionMode: .MERGE,
            items: ISSLiveCabinSymbols.subscriptionItems,
            fields: ["TimeStamp", "Value", "Status.Class"]
        )
        delegateBridge = CabinSubscriptionDelegate()
        subscription.requestedMaxFrequency = .limited(0.5)

        delegateBridge.onItemValue = { [weak self] itemID, value in
            Task { @MainActor in
                self?.apply(itemID: itemID, value: value)
            }
        }
        delegateBridge.onSubscriptionError = { [weak self] message in
            Task { @MainActor in
                self?.onStatusChange?(message)
            }
        }

        subscription.addDelegate(delegateBridge)
        client.addDelegate(ConnectionDelegateBridge { [weak self] message in
            Task { @MainActor in
                self?.onStatusChange?(message)
            }
        })
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        onStatusChange?("Connecting to NASA ISSLIVE…")
        client.connect()
        client.subscribe(subscription)
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        client.unsubscribe(subscription)
        client.disconnect()
        onStatusChange?(nil)
    }

    private func apply(itemID: String, value: String?) {
        telemetry.apply(itemID: itemID, value: value)
        onTelemetryChange?(telemetry)
        if telemetry.hasAnyValue {
            onStatusChange?(nil)
        }
    }
}

private final class CabinSubscriptionDelegate: SubscriptionDelegate {
    var onItemValue: ((String, String?) -> Void)?
    var onSubscriptionError: ((String) -> Void)?

    func subscription(_ subscription: Subscription, didUpdateItem itemUpdate: ItemUpdate) {
        guard let itemName = itemUpdate.itemName else { return }
        let value = itemUpdate.value(withFieldName: "Value")
        onItemValue?(itemName, value)
    }

    func subscription(_ subscription: Subscription, didClearSnapshotForItemName itemName: String?, itemPos: UInt) {}
    func subscription(_ subscription: Subscription, didLoseUpdates lostUpdates: UInt, forCommandSecondLevelItemWithKey key: String) {}
    func subscription(_ subscription: Subscription, didFailWithErrorCode code: Int, message: String?, forCommandSecondLevelItemWithKey key: String) {}
    func subscription(_ subscription: Subscription, didEndSnapshotForItemName itemName: String?, itemPos: UInt) {}
    func subscription(_ subscription: Subscription, didLoseUpdates lostUpdates: UInt, forItemName itemName: String?, itemPos: UInt) {}
    func subscriptionDidRemoveDelegate(_ subscription: Subscription) {}
    func subscriptionDidAddDelegate(_ subscription: Subscription) {}
    func subscriptionDidSubscribe(_ subscription: Subscription) {}
    func subscription(_ subscription: Subscription, didFailWithErrorCode code: Int, message: String?) {
        let text = message?.isEmpty == false ? message! : "Cabin subscription error (\(code))"
        onSubscriptionError?(text)
    }
    func subscriptionDidUnsubscribe(_ subscription: Subscription) {}
    func subscription(_ subscription: Subscription, didReceiveRealFrequency frequency: RealMaxFrequency?) {}
}

private final class ConnectionDelegateBridge: ClientDelegate {
    var onStatus: (String?) -> Void

    init(onStatus: @escaping (String?) -> Void) {
        self.onStatus = onStatus
    }

    func clientDidRemoveDelegate(_ client: LightstreamerClient) {}
    func clientDidAddDelegate(_ client: LightstreamerClient) {}

    func client(_ client: LightstreamerClient, didChangeStatus status: LightstreamerClient.Status) {
        switch status {
        case .CONNECTED_WS_STREAMING, .CONNECTED_HTTP_STREAMING, .CONNECTED_WS_POLLING, .CONNECTED_HTTP_POLLING:
            onStatus(nil)
        case .CONNECTING, .CONNECTED_STREAM_SENSING:
            onStatus("Connecting to cabin feed…")
        case .DISCONNECTED, .DISCONNECTED_WILL_RETRY, .DISCONNECTED_TRYING_RECOVERY:
            onStatus("Cabin feed disconnected")
        default:
            break
        }
    }

    func client(_ client: LightstreamerClient, didChangeProperty property: String) {}

    func client(_ client: LightstreamerClient, didReceiveServerError errorCode: Int, withMessage errorMessage: String) {
        onStatus(errorMessage.isEmpty ? "Cabin feed error (\(errorCode))" : errorMessage)
    }
}
