//
// LoadTestingEngine.swift
// KiteKit
//
// Synthetic Load & Performance Engineering Engine (Phase 27).
// Computes Gunther's Universal Scalability Law (USL) retrograde contention knees and
// Little's Law concurrency depth across architecture services, and synthesizes executable
// Grafana k6 and Python Locust distributed load-testing suites with SLA thresholds.
//

import Foundation

public struct ServiceLoadProfile: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let serviceId: String
    public let endpointPath: String
    public let baselineSingleWorkerRps: Double
    public let contentionSigma: Double
    public let coherencyKappa: Double
    public let targetP99LatencyMs: Double

    public init(
        id: String,
        serviceId: String,
        endpointPath: String,
        baselineSingleWorkerRps: Double,
        contentionSigma: Double,
        coherencyKappa: Double,
        targetP99LatencyMs: Double
    ) {
        self.id = id
        self.serviceId = serviceId
        self.endpointPath = endpointPath
        self.baselineSingleWorkerRps = baselineSingleWorkerRps
        self.contentionSigma = contentionSigma
        self.coherencyKappa = coherencyKappa
        self.targetP99LatencyMs = targetP99LatencyMs
    }
}

public struct UslScalabilityForecast: Codable, Sendable, Equatable {
    public let serviceId: String
    public let concurrencyN: Int
    public let relativeCapacityFactor: Double
    public let projectedThroughputRps: Double
    public let optimalConcurrencyKnee: Int
    public let littlesLawInFlightRequests: Double
    public let isRetrogradeRegion: Bool

    public init(
        serviceId: String,
        concurrencyN: Int,
        relativeCapacityFactor: Double,
        projectedThroughputRps: Double,
        optimalConcurrencyKnee: Int,
        littlesLawInFlightRequests: Double,
        isRetrogradeRegion: Bool
    ) {
        self.serviceId = serviceId
        self.concurrencyN = concurrencyN
        self.relativeCapacityFactor = relativeCapacityFactor
        self.projectedThroughputRps = projectedThroughputRps
        self.optimalConcurrencyKnee = optimalConcurrencyKnee
        self.littlesLawInFlightRequests = littlesLawInFlightRequests
        self.isRetrogradeRegion = isRetrogradeRegion
    }
}

public struct SyntheticLoadBundle: Codable, Sendable, Equatable {
    public let serviceId: String
    public let targetVus: Int
    public let durationSec: Int
    public let k6ScriptJs: String
    public let locustFilePy: String

    public init(
        serviceId: String,
        targetVus: Int,
        durationSec: Int,
        k6ScriptJs: String,
        locustFilePy: String
    ) {
        self.serviceId = serviceId
        self.targetVus = targetVus
        self.durationSec = durationSec
        self.k6ScriptJs = k6ScriptJs
        self.locustFilePy = locustFilePy
    }
}

public final class LoadTestingEngine: @unchecked Sendable {
    public static let shared = LoadTestingEngine()

    private let lock = NSLock()
    private var profiles: [ServiceLoadProfile] = []

    public init() {
        seedProfiles()
    }

    private func seedProfiles() {
        profiles = [
            ServiceLoadProfile(
                id: "load-checkout",
                serviceId: "checkout-api",
                endpointPath: "/v1/orders/checkout",
                baselineSingleWorkerRps: 420.0,
                contentionSigma: 0.04,
                coherencyKappa: 0.0015,
                targetP99LatencyMs: 95.0
            ),
            ServiceLoadProfile(
                id: "load-ledger",
                serviceId: "ledger-writer",
                endpointPath: "/v1/ledger/commit",
                baselineSingleWorkerRps: 180.0,
                contentionSigma: 0.08,
                coherencyKappa: 0.0040,
                targetP99LatencyMs: 60.0
            ),
            ServiceLoadProfile(
                id: "load-search",
                serviceId: "search-indexer",
                endpointPath: "/v1/catalog/query",
                baselineSingleWorkerRps: 950.0,
                contentionSigma: 0.02,
                coherencyKappa: 0.0005,
                targetP99LatencyMs: 45.0
            )
        ]
    }

    public func getProfiles() -> [ServiceLoadProfile] {
        lock.lock()
        defer { lock.unlock() }
        return profiles
    }

    public func evaluateUslModel(serviceId: String = "checkout-api", concurrencyN: Int = 16) -> UslScalabilityForecast {
        lock.lock()
        let prof = profiles.first(where: { $0.serviceId == serviceId }) ?? profiles[0]
        lock.unlock()

        let n = max(1, concurrencyN)
        let nDouble = Double(n)
        let sigma = prof.contentionSigma
        let kappa = max(0.000001, prof.coherencyKappa)

        // Gunther's Universal Scalability Law: C(N) = N / (1 + sigma*(N-1) + kappa*N*(N-1))
        let denom = 1.0 + sigma * (nDouble - 1.0) + kappa * nDouble * (nDouble - 1.0)
        let cFactor = ((nDouble / denom) * 100.0).rounded() / 100.0
        let throughput = ((prof.baselineSingleWorkerRps * (nDouble / denom)) * 10.0).rounded() / 10.0

        let knee = max(1, Int(floor(sqrt(max(0.0, 1.0 - sigma) / kappa))))
        let latencySec = prof.targetP99LatencyMs / 1000.0
        let inFlight = ((throughput * latencySec) * 100.0).rounded() / 100.0

        return UslScalabilityForecast(
            serviceId: prof.serviceId,
            concurrencyN: n,
            relativeCapacityFactor: cFactor,
            projectedThroughputRps: throughput,
            optimalConcurrencyKnee: knee,
            littlesLawInFlightRequests: inFlight,
            isRetrogradeRegion: n > knee
        )
    }

    public func synthesizeLoadScripts(
        serviceId: String = "checkout-api",
        targetVus: Int = 200,
        durationSec: Int = 120
    ) -> SyntheticLoadBundle {
        lock.lock()
        let prof = profiles.first(where: { $0.serviceId == serviceId }) ?? profiles[0]
        lock.unlock()

        let vus = max(10, targetVus)
        let dur = max(30, durationSec)
        let p99Int = Int(prof.targetP99LatencyMs)
        let rampUp = max(10, dur / 4)
        let steady = max(10, dur - (2 * rampUp))

        let k6Js = """
        import http from 'k6/http';
        import { check, sleep } from 'k6';

        export const options = {
          scenarios: {
            kite_usl_profile: {
              executor: 'ramping-vus',
              startVUs: 1,
              stages: [
                { duration: '\(rampUp)s', target: \(vus) },
                { duration: '\(steady)s', target: \(vus) },
                { duration: '\(rampUp)s', target: 0 },
              ],
            },
          },
          thresholds: {
            http_req_failed: ['rate<0.005'],
            http_req_duration: ['p(99)<\(p99Int)'],
          },
        };

        export default function () {
          const baseUrl = __ENV.KITE_TARGET_URL || 'https://api.kite.internal';
          const res = http.post(`${baseUrl}\(prof.endpointPath)`, JSON.stringify({ syntheticProbe: true }), {
            headers: { 'Content-Type': 'application/json' },
          });
          check(res, { 'status is 200': (r) => r.status === 200 });
          sleep(0.1);
        }
        """

        let locustPy = """
        from locust import HttpUser, task, between

        class KiteSyntheticSwarmUser(HttpUser):
            wait_time = between(0.05, 0.25)

            @task(1)
            def exercise_\(prof.serviceId.replacingOccurrences(of: "-", with: "_"))(self):
                with self.client.post(
                    "\(prof.endpointPath)",
                    json={"syntheticProbe": True, "service": "\(prof.serviceId)"},
                    catch_response=True,
                ) as resp:
                    if resp.status_code != 200:
                        resp.failure(f"Unexpected HTTP {resp.status_code}")
                    elif resp.elapsed.total_seconds() * 1000.0 > \(p99Int):
                        resp.failure("SLA P99 threshold breached")
        """

        return SyntheticLoadBundle(
            serviceId: prof.serviceId,
            targetVus: vus,
            durationSec: dur,
            k6ScriptJs: k6Js,
            locustFilePy: locustPy
        )
    }
}
