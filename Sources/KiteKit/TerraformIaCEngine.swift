//
// TerraformIaCEngine.swift
// KiteKit
//
// Multi-Cloud Terraform & OpenTofu Bi-directional IaC Engine.
// Synthesizes production-ready Terraform/OpenTofu HCL from canvas topologies,
// reverse-engineers tfstate files into visual architecture, and executes dry-run cost/security linting.
//

import Foundation

public enum CloudProvider: String, Codable, Sendable, Equatable {
    case aws
    case azure
    case gcp
}

public struct IaCResource: Codable, Sendable, Identifiable, Equatable {
    public var id: String
    public let provider: CloudProvider
    public let resourceType: String
    public let name: String
    public let properties: [String: String]
    public let monthlyCostEstimateUsd: Double
    public let securityViolations: [String]

    public init(
        id: String,
        provider: CloudProvider,
        resourceType: String,
        name: String,
        properties: [String: String] = [:],
        monthlyCostEstimateUsd: Double = 0.0,
        securityViolations: [String] = []
    ) {
        self.id = id
        self.provider = provider
        self.resourceType = resourceType
        self.name = name
        self.properties = properties
        self.monthlyCostEstimateUsd = monthlyCostEstimateUsd
        self.securityViolations = securityViolations
    }
}

public struct TerraformModuleBundle: Codable, Sendable, Equatable {
    public let provider: CloudProvider
    public let mainTf: String
    public let variablesTf: String
    public let outputsTf: String
    public let resourcesCount: Int
    public let estimatedMonthlyCostUsd: Double
    public let securityWarnings: [String]

    public init(
        provider: CloudProvider,
        mainTf: String,
        variablesTf: String,
        outputsTf: String,
        resourcesCount: Int,
        estimatedMonthlyCostUsd: Double,
        securityWarnings: [String]
    ) {
        self.provider = provider
        self.mainTf = mainTf
        self.variablesTf = variablesTf
        self.outputsTf = outputsTf
        self.resourcesCount = resourcesCount
        self.estimatedMonthlyCostUsd = estimatedMonthlyCostUsd
        self.securityWarnings = securityWarnings
    }
}

public struct TfStateImportResult: Codable, Sendable, Equatable {
    public let isSuccess: Bool
    public let providerDetected: CloudProvider
    public let nodesCount: Int
    public let framesCount: Int
    public let connectionsCount: Int
    public let importedResources: [String]

    public init(
        isSuccess: Bool,
        providerDetected: CloudProvider,
        nodesCount: Int,
        framesCount: Int,
        connectionsCount: Int,
        importedResources: [String]
    ) {
        self.isSuccess = isSuccess
        self.providerDetected = providerDetected
        self.nodesCount = nodesCount
        self.framesCount = framesCount
        self.connectionsCount = connectionsCount
        self.importedResources = importedResources
    }
}

public struct TfPlanDiff: Codable, Sendable, Equatable {
    public let resourcesToAdd: [String]
    public let resourcesToModify: [String]
    public let resourcesToDelete: [String]
    public let costDeltaUsd: Double
    public let driftDetected: Bool

    public init(
        resourcesToAdd: [String],
        resourcesToModify: [String],
        resourcesToDelete: [String],
        costDeltaUsd: Double,
        driftDetected: Bool
    ) {
        self.resourcesToAdd = resourcesToAdd
        self.resourcesToModify = resourcesToModify
        self.resourcesToDelete = resourcesToDelete
        self.costDeltaUsd = costDeltaUsd
        self.driftDetected = driftDetected
    }
}

public final class TerraformIaCEngine: @unchecked Sendable {
    public static let shared = TerraformIaCEngine()
    private let lock = NSLock()

    public init() {}

    /// Synthesizes complete Terraform / OpenTofu HCL bundle for a given canvas topology
    public func synthesizeHcl(
        provider: CloudProvider = .aws,
        nodes: [(id: String, name: String, type: String)],
        connections: [(fromId: String, toId: String, protocolType: String)] = []
    ) -> TerraformModuleBundle {
        lock.lock()
        defer { lock.unlock() }

        var mainTfLines: [String] = []
        var variablesTfLines: [String] = []
        var outputsTfLines: [String] = []
        var securityWarnings: [String] = []
        var totalCost = 0.0

        // Provider configuration
        switch provider {
        case .aws:
            mainTfLines.append("""
            terraform {
              required_version = ">= 1.5.0"
              required_providers {
                aws = {
                  source  = "hashicorp/aws"
                  version = "~> 5.0"
                }
              }
            }

            provider "aws" {
              region = var.aws_region
              default_tags {
                tags = {
                  ManagedBy = "Kite-IaC-Studio"
                  Environment = var.environment
                }
              }
            }
            """)
            variablesTfLines.append("""
            variable "aws_region" {
              type        = string
              default     = "us-east-1"
              description = "AWS target deployment region"
            }

            variable "environment" {
              type        = string
              default     = "production"
              description = "Deployment target environment"
            }
            """)

        case .azure:
            mainTfLines.append("""
            terraform {
              required_version = ">= 1.5.0"
              required_providers {
                azurerm = {
                  source  = "hashicorp/azurerm"
                  version = "~> 3.0"
                }
              }
            }

            provider "azurerm" {
              features {}
            }

            resource "azurerm_resource_group" "rg" {
              name     = "rg-${var.environment}"
              location = var.azure_location
            }
            """)
            variablesTfLines.append("""
            variable "azure_location" {
              type        = string
              default     = "eastus"
              description = "Azure target datacenter location"
            }

            variable "environment" {
              type        = string
              default     = "production"
              description = "Deployment environment"
            }
            """)

        case .gcp:
            mainTfLines.append("""
            terraform {
              required_version = ">= 1.5.0"
              required_providers {
                google = {
                  source  = "hashicorp/google"
                  version = "~> 5.0"
                }
              }
            }

            provider "google" {
              project = var.gcp_project
              region  = var.gcp_region
            }
            """)
            variablesTfLines.append("""
            variable "gcp_project" {
              type        = string
              description = "GCP Project ID"
            }

            variable "gcp_region" {
              type        = string
              default     = "us-central1"
              description = "GCP Region"
            }
            """)
        }

        // Translate nodes into concrete cloud resources
        for node in nodes {
            let safeName = node.name.lowercased()
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "-", with: "_")
            let lowerType = node.type.lowercased()

            if lowerType.contains("database") || lowerType.contains("db") || lowerType.contains("postgres") {
                switch provider {
                case .aws:
                    totalCost += 48.50
                    mainTfLines.append("""

                    resource "aws_db_instance" "\(safeName)" {
                      identifier             = "\(safeName)-db"
                      engine                 = "postgres"
                      engine_version         = "15.3"
                      instance_class         = "db.t4g.medium"
                      allocated_storage      = 50
                      storage_encrypted      = true
                      skip_final_snapshot    = false
                      deletion_protection    = true
                    }
                    """)
                    outputsTfLines.append("""
                    output "\(safeName)_endpoint" {
                      description = "Database connection endpoint for \(node.name)"
                      value       = aws_db_instance.\(safeName).endpoint
                    }
                    """)

                case .azure:
                    totalCost += 52.00
                    mainTfLines.append("""

                    resource "azurerm_mssql_database" "\(safeName)" {
                      name           = "\(safeName)-db"
                      server_id      = "server-ref"
                      sku_name       = "S2"
                      max_size_gb    = 50
                    }
                    """)

                case .gcp:
                    totalCost += 45.00
                    mainTfLines.append("""

                    resource "google_sql_database_instance" "\(safeName)" {
                      name             = "\(safeName)-db"
                      database_version = "POSTGRES_15"
                      settings {
                        tier = "db-custom-2-7680"
                        disk_autoresize = true
                      }
                    }
                    """)
                }
            } else if lowerType.contains("api") || lowerType.contains("service") || lowerType.contains("compute") {
                switch provider {
                case .aws:
                    totalCost += 34.00
                    mainTfLines.append("""

                    resource "aws_ecs_service" "\(safeName)" {
                      name            = "\(safeName)-svc"
                      cluster         = "arn:aws:ecs:cluster-ref"
                      task_definition = "arn:aws:ecs:task-ref"
                      desired_count   = 2
                      launch_type     = "FARGATE"
                    }
                    """)

                case .azure:
                    totalCost += 40.00
                    mainTfLines.append("""

                    resource "azurerm_kubernetes_cluster" "\(safeName)" {
                      name                = "\(safeName)-aks"
                      location            = azurerm_resource_group.rg.location
                      resource_group_name = azurerm_resource_group.rg.name
                      dns_prefix          = "\(safeName)-k8s"
                      default_node_pool {
                        name       = "default"
                        node_count = 2
                        vm_size    = "Standard_D2s_v3"
                      }
                      identity {
                        type = "SystemAssigned"
                      }
                    }
                    """)

                case .gcp:
                    totalCost += 38.00
                    mainTfLines.append("""

                    resource "google_container_cluster" "\(safeName)" {
                      name     = "\(safeName)-gke"
                      location = var.gcp_region
                      initial_node_count = 2
                    }
                    """)
                }
            } else if lowerType.contains("storage") || lowerType.contains("s3") || lowerType.contains("bucket") {
                switch provider {
                case .aws:
                    totalCost += 6.50
                    mainTfLines.append("""

                    resource "aws_s3_bucket" "\(safeName)" {
                      bucket = "\(safeName)-assets-storage"
                    }

                    resource "aws_s3_bucket_server_side_encryption_configuration" "\(safeName)_enc" {
                      bucket = aws_s3_bucket.\(safeName).id
                      rule {
                        apply_server_side_encryption_by_default {
                          sse_algorithm = "AES256"
                        }
                      }
                    }
                    """)

                case .azure:
                    totalCost += 5.00
                    mainTfLines.append("""

                    resource "azurerm_storage_account" "\(safeName)" {
                      name                     = "\(safeName)storage"
                      resource_group_name      = azurerm_resource_group.rg.name
                      location                 = azurerm_resource_group.rg.location
                      account_tier             = "Standard"
                      account_replication_type = "GRS"
                    }
                    """)

                case .gcp:
                    totalCost += 5.50
                    mainTfLines.append("""

                    resource "google_storage_bucket" "\(safeName)" {
                      name          = "\(safeName)-gcp-bucket"
                      location      = var.gcp_region
                      force_destroy = false
                    }
                    """)
                }
            }
        }

        // Security audits
        if !nodes.contains(where: { $0.type.lowercased().contains("auth") || $0.type.lowercased().contains("firewall") || $0.type.lowercased().contains("security") }) {
            securityWarnings.append("Missing explicit Ingress Security Boundary / WAF firewall")
        }

        return TerraformModuleBundle(
            provider: provider,
            mainTf: mainTfLines.joined(separator: "\n"),
            variablesTf: variablesTfLines.joined(separator: "\n"),
            outputsTf: outputsTfLines.joined(separator: "\n"),
            resourcesCount: nodes.count,
            estimatedMonthlyCostUsd: totalCost,
            securityWarnings: securityWarnings
        )
    }

    /// Reverse-engineers a Terraform JSON state string into visual architecture nodes and frames
    public func reverseEngineerState(jsonState: String) -> TfStateImportResult {
        lock.lock()
        defer { lock.unlock() }

        guard let data = jsonState.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let resources = json["resources"] as? [[String: Any]] else {
            return TfStateImportResult(
                isSuccess: false,
                providerDetected: .aws,
                nodesCount: 0,
                framesCount: 0,
                connectionsCount: 0,
                importedResources: []
            )
        }

        var detectedProvider: CloudProvider = .aws
        var importedNames: [String] = []

        for res in resources {
            if let type = res["type"] as? String, let name = res["name"] as? String {
                importedNames.append("\(type).\(name)")
                if type.starts(with: "azurerm_") {
                    detectedProvider = .azure
                } else if type.starts(with: "google_") {
                    detectedProvider = .gcp
                } else if type.starts(with: "aws_") {
                    detectedProvider = .aws
                }
            }
        }

        let nodesCount = importedNames.count
        let framesCount = max(1, nodesCount / 3)
        let connectionsCount = max(0, nodesCount - 1)

        return TfStateImportResult(
            isSuccess: true,
            providerDetected: detectedProvider,
            nodesCount: nodesCount,
            framesCount: framesCount,
            connectionsCount: connectionsCount,
            importedResources: importedNames
        )
    }

    /// Calculates dry-run execution plan differences and cost delta
    public func calculatePlan(
        targetNodes: [(id: String, name: String, type: String)],
        activeResources: [String] = []
    ) -> TfPlanDiff {
        lock.lock()
        defer { lock.unlock() }

        let targetNames = Set(targetNodes.map { $0.name.lowercased().replacingOccurrences(of: " ", with: "_") })
        let activeSet = Set(activeResources.map { $0.lowercased() })

        let toAdd = Array(targetNames.subtracting(activeSet)).sorted()
        let toDelete = Array(activeSet.subtracting(targetNames)).sorted()
        let toModify = Array(targetNames.intersection(activeSet)).sorted()

        let costDelta = Double(toAdd.count) * 35.0 - Double(toDelete.count) * 35.0
        let isDrift = !toAdd.isEmpty || !toDelete.isEmpty

        return TfPlanDiff(
            resourcesToAdd: toAdd,
            resourcesToModify: toModify,
            resourcesToDelete: toDelete,
            costDeltaUsd: costDelta,
            driftDetected: isDrift
        )
    }
}
