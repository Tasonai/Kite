import Foundation

public struct StoragePolicyConfig: Identifiable, Sendable, Equatable {
    public var id: String { bucketName }
    public var bucketName: String
    public var allowedMimeTypes: [String]
    public var maxSizeBytes: Int
    public var isPublic: Bool
    public var presignedUrlTtlSeconds: Int
    public var storageProvider: String

    public init(
        bucketName: String,
        allowedMimeTypes: [String],
        maxSizeBytes: Int,
        isPublic: Bool,
        presignedUrlTtlSeconds: Int,
        storageProvider: String
    ) {
        self.bucketName = bucketName
        self.allowedMimeTypes = allowedMimeTypes
        self.maxSizeBytes = maxSizeBytes
        self.isPublic = isPublic
        self.presignedUrlTtlSeconds = presignedUrlTtlSeconds
        self.storageProvider = storageProvider
    }
}

public enum StorageGuard {
    public static var starterPolicies: [StoragePolicyConfig] {
        [
            StoragePolicyConfig(
                bucketName: "user-avatars",
                allowedMimeTypes: ["image/jpeg", "image/png", "image/webp"],
                maxSizeBytes: 5 * 1024 * 1024,
                isPublic: true,
                presignedUrlTtlSeconds: 300,
                storageProvider: "Supabase Storage"
            ),
            StoragePolicyConfig(
                bucketName: "project-exports",
                allowedMimeTypes: ["application/pdf", "image/svg+xml", "application/json", "application/zip"],
                maxSizeBytes: 50 * 1024 * 1024,
                isPublic: false,
                presignedUrlTtlSeconds: 900,
                storageProvider: "Cloudflare R2"
            ),
            StoragePolicyConfig(
                bucketName: "encrypted-vault",
                allowedMimeTypes: ["application/octet-stream", "application/x-tar"],
                maxSizeBytes: 200 * 1024 * 1024,
                isPublic: false,
                presignedUrlTtlSeconds: 60,
                storageProvider: "AWS S3"
            )
        ]
    }

    public static func generateStorageMarkdown(title: String, policies: [StoragePolicyConfig]) -> String {
        var lines: [String] = [
            "# CLOUD STORAGE SECURITY & UPLOAD POLICY: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in enforcing strict file upload boundaries.",
            "NEVER accept unbounded file buffers in server memory. Always generate authenticated Presigned URLs.",
            ""
        ]

        for (idx, p) in policies.enumerated() {
            let maxMb = p.maxSizeBytes / (1024 * 1024)
            lines.append("## \(idx + 1). Bucket `\(p.bucketName)` (\(p.storageProvider))")
            lines.append("- Access Level: \(p.isPublic ? "Public CDN" : "Private / Presigned Only")")
            lines.append("- Allowed Content-Types: `\(p.allowedMimeTypes.joined(separator: ", "))`")
            lines.append("- Max File Size: \(maxMb) MB (\(p.maxSizeBytes) bytes)")
            lines.append("- Presigned URL Expiration: \(p.presignedUrlTtlSeconds) seconds")
            lines.append("")
        }

        lines.append("## Upload Validation Security Rules")
        lines.append("1. Validate MIME types via Magic Bytes sniffing on the client before requesting Presigned URLs.")
        lines.append("2. Enforce Content-Length checks in bucket CORS and upload policy.")
        lines.append("3. Strip EXIF GPS metadata from images before saving to storage.")

        return lines.joined(separator: "\n")
    }

    public static func generatePresignedUploadSnippet(policy: StoragePolicyConfig) -> String {
        let maxMb = policy.maxSizeBytes / (1024 * 1024)
        let lines: [String] = [
            "// app/api/storage/presigned-url/route.ts",
            "// Secure presigned upload generator for \(policy.storageProvider)",
            "import { NextResponse } from 'next/server';",
            "import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';",
            "import { getSignedUrl } from '@aws-sdk/s3-request-presigner';",
            "",
            "const s3 = new S3Client({",
            "  region: process.env.STORAGE_REGION || 'auto',",
            "  endpoint: process.env.STORAGE_ENDPOINT,",
            "  credentials: {",
            "    accessKeyId: process.env.STORAGE_ACCESS_KEY!,",
            "    secretAccessKey: process.env.STORAGE_SECRET_KEY!,",
            "  },",
            "});",
            "",
            "const ALLOWED_MIME = new Set([\(policy.allowedMimeTypes.map { "'\($0)'" }.joined(separator: ", "))]);",
            "const MAX_SIZE_BYTES = \(policy.maxSizeBytes); // \(maxMb) MB",
            "",
            "export async function POST(req: Request) {",
            "  const { fileName, contentType, sizeBytes } = await req.json();",
            "",
            "  if (!ALLOWED_MIME.has(contentType)) {",
            "    return NextResponse.json({ error: 'MIME type disallowed' }, { status: 400 });",
            "  }",
            "",
            "  if (sizeBytes > MAX_SIZE_BYTES) {",
            "    return NextResponse.json({ error: 'File exceeds maximum size limit' }, { status: 413 });",
            "  }",
            "",
            "  const safeKey = `${crypto.randomUUID()}-${fileName.replace(/[^a-zA-Z0-9.-]/g, '_')}`;",
            "  const command = new PutObjectCommand({",
            "    Bucket: '\(policy.bucketName)',",
            "    Key: safeKey,",
            "    ContentType: contentType,",
            "  });",
            "",
            "  const presignedUrl = await getSignedUrl(s3, command, { expiresIn: \(policy.presignedUrlTtlSeconds) });",
            "  return NextResponse.json({ presignedUrl, key: safeKey });",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(policies: [StoragePolicyConfig]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY STORAGE SECURITY DIRECTIVE]",
            "Enforce strict Cloud Storage rules across S3, Cloudflare R2, or Supabase Storage:",
            ""
        ]

        for p in policies {
            lines.append("- [\(p.bucketName)]: max \(p.maxSizeBytes / (1024 * 1024))MB, types [\(p.allowedMimeTypes.joined(separator: ", "))], TTL \(p.presignedUrlTtlSeconds)s")
        }

        lines.append("")
        lines.append("Never buffer large file streams in RAM. Always generate secure presigned upload URLs.")
        return lines.joined(separator: "\n")
    }
}
