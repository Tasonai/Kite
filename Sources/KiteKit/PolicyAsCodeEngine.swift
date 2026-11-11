//
// PolicyAsCodeEngine.swift
// KiteKit
//
// Policy-as-Code Authorization Engine (Phase 28).
// Evaluates ABAC/ReBAC fine-grained access decisions with explicit forbid-overrides-permit
// semantics across canvas service boundaries, and synthesizes Open Policy Agent (OPA Rego v1)
// modules alongside AWS Cedar schema-backed policy sets.
//

import Foundation

public struct AuthorizationPolicyRule: Codable, Sendable, Identifiable, Equatable {
    public let id: String
    public let effect: String
    public let principalRole: String
    public let action: String
    public let resourceType: String
    public let conditionSummary: String

    public init(
        id: String,
        effect: String,
        principalRole: String,
        action: String,
        resourceType: String,
        conditionSummary: String
    ) {
        self.id = id
        self.effect = effect
        self.principalRole = principalRole
        self.action = action
        self.resourceType = resourceType
        self.conditionSummary = conditionSummary
    }
}

public struct PolicyDecisionVerdict: Codable, Sendable, Equatable {
    public let allowed: Bool
    public let matchedRuleId: String
    public let denyOverridesTriggered: Bool
    public let reason: String

    public init(
        allowed: Bool,
        matchedRuleId: String,
        denyOverridesTriggered: Bool,
        reason: String
    ) {
        self.allowed = allowed
        self.matchedRuleId = matchedRuleId
        self.denyOverridesTriggered = denyOverridesTriggered
        self.reason = reason
    }
}

public struct PolicyAsCodeBundle: Codable, Sendable, Equatable {
    public let namespace: String
    public let opaRegoModule: String
    public let cedarPolicySet: String

    public init(namespace: String, opaRegoModule: String, cedarPolicySet: String) {
        self.namespace = namespace
        self.opaRegoModule = opaRegoModule
        self.cedarPolicySet = cedarPolicySet
    }
}

public final class PolicyAsCodeEngine: @unchecked Sendable {
    public static let shared = PolicyAsCodeEngine()

    private let lock = NSLock()
    private var rules: [AuthorizationPolicyRule] = []

    public init() {
        seedRules()
    }

    private func seedRules() {
        rules = [
            AuthorizationPolicyRule(
                id: "pol-forbid-unverified-mfa",
                effect: "forbid",
                principalRole: "*",
                action: "ledger:ApproveSettlement",
                resourceType: "SettlementBatch",
                conditionSummary: "context.mfaVerified == false"
            ),
            AuthorizationPolicyRule(
                id: "pol-permit-treasury-settle",
                effect: "permit",
                principalRole: "treasury-operator",
                action: "ledger:ApproveSettlement",
                resourceType: "SettlementBatch",
                conditionSummary: "principal.role == treasury-operator && context.mfaVerified == true"
            ),
            AuthorizationPolicyRule(
                id: "pol-permit-sre-rollout",
                effect: "permit",
                principalRole: "sre-oncall",
                action: "mesh:DrainTraffic",
                resourceType: "CanaryService",
                conditionSummary: "principal.role == sre-oncall"
            ),
            AuthorizationPolicyRule(
                id: "pol-forbid-auditor-mutate",
                effect: "forbid",
                principalRole: "compliance-auditor",
                action: "ledger:ApproveSettlement",
                resourceType: "SettlementBatch",
                conditionSummary: "read-only auditor separation of duties"
            )
        ]
    }

    public func getRules() -> [AuthorizationPolicyRule] {
        lock.lock()
        defer { lock.unlock() }
        return rules
    }

    public func evaluateAccess(
        principalRole: String = "treasury-operator",
        action: String = "ledger:ApproveSettlement",
        resourceType: String = "SettlementBatch",
        mfaVerified: Bool = true
    ) -> PolicyDecisionVerdict {
        lock.lock()
        let snapshot = rules
        lock.unlock()

        // 1. Explicit forbid-overrides-permit check
        if action == "ledger:ApproveSettlement" && !mfaVerified {
            return PolicyDecisionVerdict(
                allowed: false,
                matchedRuleId: "pol-forbid-unverified-mfa",
                denyOverridesTriggered: true,
                reason: "Explicit FORBID: ledger:ApproveSettlement requires hardware WebAuthn/MFA verification."
            )
        }

        if let explicitForbid = snapshot.first(where: {
            $0.effect == "forbid"
                && $0.principalRole == principalRole
                && $0.action == action
                && $0.resourceType == resourceType
        }) {
            return PolicyDecisionVerdict(
                allowed: false,
                matchedRuleId: explicitForbid.id,
                denyOverridesTriggered: true,
                reason: "Explicit FORBID matched rule \(explicitForbid.id) (\(explicitForbid.conditionSummary))."
            )
        }

        // 2. Explicit permit check
        if let permitRule = snapshot.first(where: {
            $0.effect == "permit"
                && ($0.principalRole == principalRole || $0.principalRole == "*")
                && $0.action == action
                && $0.resourceType == resourceType
        }) {
            return PolicyDecisionVerdict(
                allowed: true,
                matchedRuleId: permitRule.id,
                denyOverridesTriggered: false,
                reason: "PERMIT granted via rule \(permitRule.id)."
            )
        }

        // 3. Default deny
        return PolicyDecisionVerdict(
            allowed: false,
            matchedRuleId: "default-zero-trust-deny",
            denyOverridesTriggered: false,
            reason: "Default zero-trust DENY: no matching permit policy for \(principalRole) on \(action)."
        )
    }

    public func synthesizePolicyBundle(namespace: String = "kite.authz.v1") -> PolicyAsCodeBundle {
        let pkg = namespace.replacingOccurrences(of: "-", with: "_")

        let rego = """
        package \(pkg)
        import rego.v1

        default allow := false

        explicit_deny if {
            input.action == "ledger:ApproveSettlement"
            not input.context.mfa_verified
        }

        explicit_deny if {
            input.principal.role == "compliance-auditor"
            startswith(input.action, "ledger:Approve")
        }

        allow if {
            not explicit_deny
            input.principal.role == "treasury-operator"
            input.action == "ledger:ApproveSettlement"
            input.resource.type == "SettlementBatch"
        }

        allow if {
            not explicit_deny
            input.principal.role == "sre-oncall"
            input.action == "mesh:DrainTraffic"
            input.resource.type == "CanaryService"
        }
        """

        let cedar = """
        @id("pol-forbid-unverified-mfa")
        forbid (
            principal,
            action == Kite::Action::"ledger:ApproveSettlement",
            resource is Kite::SettlementBatch
        )
        unless {
            context.mfaVerified == true
        };

        @id("pol-permit-treasury-settle")
        permit (
            principal in Kite::Role::"treasury-operator",
            action == Kite::Action::"ledger:ApproveSettlement",
            resource is Kite::SettlementBatch
        )
        when {
            context.mfaVerified == true
        };

        @id("pol-permit-sre-rollout")
        permit (
            principal in Kite::Role::"sre-oncall",
            action == Kite::Action::"mesh:DrainTraffic",
            resource is Kite::CanaryService
        );
        """

        return PolicyAsCodeBundle(
            namespace: pkg,
            opaRegoModule: rego,
            cedarPolicySet: cedar
        )
    }
}
