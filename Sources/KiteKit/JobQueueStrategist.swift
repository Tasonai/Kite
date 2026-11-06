import Foundation

public struct BackgroundJob: Identifiable, Sendable, Equatable {
    public var id: String { jobName }
    public var jobName: String
    public var triggerType: String
    public var retryLimit: Int
    public var concurrencyLimit: Int
    public var executionTimeoutSec: Int

    public init(jobName: String, triggerType: String, retryLimit: Int, concurrencyLimit: Int, executionTimeoutSec: Int) {
        self.jobName = jobName
        self.triggerType = triggerType
        self.retryLimit = retryLimit
        self.concurrencyLimit = concurrencyLimit
        self.executionTimeoutSec = executionTimeoutSec
    }
}

public enum JobQueueStrategist {
    public static var starterJobs: [BackgroundJob] {
        [
            BackgroundJob(
                jobName: "sync_stripe_subscriptions",
                triggerType: "Cron (every 6 hours)",
                retryLimit: 5,
                concurrencyLimit: 2,
                executionTimeoutSec: 120
            ),
            BackgroundJob(
                jobName: "generate_pdf_report",
                triggerType: "Event Queue (job.requested)",
                retryLimit: 3,
                concurrencyLimit: 4,
                executionTimeoutSec: 300
            ),
            BackgroundJob(
                jobName: "run_prompt_regression_evals",
                triggerType: "Event Queue (deploy.completed)",
                retryLimit: 2,
                concurrencyLimit: 1,
                executionTimeoutSec: 600
            )
        ]
    }

    public static func generateJobsMarkdown(title: String, jobs: [BackgroundJob]) -> String {
        var lines: [String] = [
            "# BACKGROUND JOBS & ASYNC QUEUES SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in offloading heavy work from HTTP handlers.",
            "NEVER perform long-running tasks (>1.5s) inside synchronous request lifecycles.",
            ""
        ]

        for (idx, j) in jobs.enumerated() {
            lines.append("## \(idx + 1). `\(j.jobName)`")
            lines.append("- Trigger: \(j.triggerType)")
            lines.append("- Max Retries: \(j.retryLimit) (with exponential backoff)")
            lines.append("- Concurrency Limit: \(j.concurrencyLimit)")
            lines.append("- Timeout: \(j.executionTimeoutSec) seconds")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateInngestWorkerSnippet(jobs: [BackgroundJob]) -> String {
        var lines: [String] = [
            "// inngest/functions.ts",
            "// Robust background worker definitions for Antigravity-generated apps",
            "import { Inngest } from 'inngest';",
            "",
            "export const inngest = new Inngest({ id: 'workspace-app' });",
            ""
        ]

        for j in jobs {
            lines.append("export const \(j.jobName)Fn = inngest.createFunction(")
            lines.append("  { id: '\(j.jobName)', retries: \(j.retryLimit), concurrency: \(j.concurrencyLimit) },")
            lines.append("  { event: 'app/\(j.jobName)' },")
            lines.append("  async ({ event, step }) => {")
            lines.append("    console.log('[Job Started] \(j.jobName)', event.data);")
            lines.append("    await step.run('execute-main-work', async () => {")
            lines.append("      // Offloaded background task logic")
            lines.append("      return { status: 'completed' };")
            lines.append("    });")
            lines.append("  }")
            lines.append(");")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(jobs: [BackgroundJob]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY BACKGROUND JOBS DIRECTIVE]",
            "Do NOT run heavy operations synchronously in API routes.",
            "Offload these tasks to background workers:",
            ""
        ]

        for j in jobs {
            lines.append("- `\(j.jobName)`: Triggered by \(j.triggerType). Retries: \(j.retryLimit), Concurrency: \(j.concurrencyLimit).")
        }

        lines.append("")
        lines.append("Always return immediate HTTP 202 Accepted and process tasks asynchronously.")
        return lines.joined(separator: "\n")
    }
}
