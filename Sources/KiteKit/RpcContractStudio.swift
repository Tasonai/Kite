import Foundation

public struct RpcProcedureConfig: Identifiable, Sendable, Equatable {
    public var id: String { procedureName }
    public var procedureName: String
    public var procedureType: String
    public var inputZodSchema: String
    public var outputZodSchema: String
    public var authRequirement: String

    public init(
        procedureName: String,
        procedureType: String,
        inputZodSchema: String,
        outputZodSchema: String,
        authRequirement: String
    ) {
        self.procedureName = procedureName
        self.procedureType = procedureType
        self.inputZodSchema = inputZodSchema
        self.outputZodSchema = outputZodSchema
        self.authRequirement = authRequirement
    }
}

public enum RpcContractStudio {
    public static var starterProcedures: [RpcProcedureConfig] {
        [
            RpcProcedureConfig(
                procedureName: "canvas.updateNode",
                procedureType: "Mutation",
                inputZodSchema: "z.object({ nodeId: z.string(), x: z.number(), y: z.number(), title: z.string().optional() })",
                outputZodSchema: "z.object({ success: z.boolean(), updatedAt: z.string() })",
                authRequirement: "Protected (JWT Session)"
            ),
            RpcProcedureConfig(
                procedureName: "workspace.getHierarchy",
                procedureType: "Query",
                inputZodSchema: "z.object({ workspaceId: z.string(), depth: z.number().int().min(1).max(5).default(2) })",
                outputZodSchema: "z.object({ id: z.string(), nodeCount: z.number(), status: z.string() })",
                authRequirement: "Protected (JWT Session)"
            ),
            RpcProcedureConfig(
                procedureName: "realtime.subscribeEvents",
                procedureType: "Subscription",
                inputZodSchema: "z.object({ channelId: z.string(), lastEventId: z.string().optional() })",
                outputZodSchema: "z.object({ eventId: z.string(), payload: z.record(z.string(), z.unknown()) })",
                authRequirement: "Protected (JWT Session)"
            )
        ]
    }

    public static func generateRpcMarkdown(title: String, procedures: [RpcProcedureConfig]) -> String {
        var lines: [String] = [
            "# END-TO-END TYPED RPC & TRPC SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in generating type-safe RPC procedures and Zod schemas.",
            "NEVER use untyped any payloads in RPC routes. Enforce strict runtime schema validation.",
            ""
        ]

        for (idx, p) in procedures.enumerated() {
            lines.append("## \(idx + 1). `\(p.procedureName)` [\(p.procedureType)]")
            lines.append("- Auth: \(p.authRequirement)")
            lines.append("- Input Validation: `\(p.inputZodSchema)`")
            lines.append("- Output Return Type: `\(p.outputZodSchema)`")
            lines.append("")
        }

        lines.append("## Type Safety Directives")
        lines.append("1. All procedures must export inferred TypeScript types: `type AppRouter = typeof appRouter;`.")
        lines.append("2. Inputs must throw structured TRPCError with code `BAD_REQUEST` on invalid schemas.")
        lines.append("3. Frontend calls must use `@trpc/react-query` or `@trpc/client` for autocomplete.")

        return lines.joined(separator: "\n")
    }

    public static func generateTrpcRouterSnippet(procedures: [RpcProcedureConfig]) -> String {
        let lines: [String] = [
            "// server/trpc/router.ts",
            "// End-to-end type-safe tRPC router with Zod validation",
            "import { initTRPC, TRPCError } from '@trpc/server';",
            "import { z } from 'zod';",
            "",
            "const t = initTRPC.create();",
            "const router = t.router;",
            "const publicProcedure = t.procedure;",
            "",
            "export const appRouter = router({",
            "  canvas: {",
            "    updateNode: publicProcedure",
            "      .input(z.object({ nodeId: z.string(), x: z.number(), y: z.number(), title: z.string().optional() }))",
            "      .output(z.object({ success: z.boolean(), updatedAt: z.string() }))",
            "      .mutation(async ({ input, ctx }) => {",
            "        // Perform database mutation",
            "        return { success: true, updatedAt: new Date().toISOString() };",
            "      }),",
            "  },",
            "  workspace: {",
            "    getHierarchy: publicProcedure",
            "      .input(z.object({ workspaceId: z.string(), depth: z.number().int().min(1).max(5).default(2) }))",
            "      .output(z.object({ id: z.string(), nodeCount: z.number(), status: z.string() }))",
            "      .query(async ({ input }) => {",
            "        return { id: input.workspaceId, nodeCount: 42, status: 'ready' };",
            "      }),",
            "  },",
            "});",
            "",
            "export type AppRouter = typeof appRouter;"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(procedures: [RpcProcedureConfig]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY TYPED RPC DIRECTIVE]",
            "Define all backend APIs as end-to-end typed tRPC or RPC procedures with Zod validation:",
            ""
        ]

        for p in procedures {
            lines.append("- `\(p.procedureName)`: [\(p.procedureType)] Input: `\(p.inputZodSchema)` -> Output: `\(p.outputZodSchema)`")
        }

        lines.append("")
        lines.append("Never leave parameters untyped. Ensure seamless client-side autocomplete and type inference.")
        return lines.joined(separator: "\n")
    }
}
