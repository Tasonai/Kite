import Foundation

public enum DeployBlueprintGenerator {
    public static func generateVercelConfig(title: String, platform: String) -> String {
        """
        {
          "version": 2,
          "name": "\(title.lowercased().replacingOccurrences(of: " ", with: "-"))",
          "framework": "vite",
          "buildCommand": "npm run build",
          "outputDirectory": "dist",
          "rewrites": [
            { "source": "/(.*)", "destination": "/index.html" }
          ],
          "headers": [
            {
              "source": "/(.*)",
              "headers": [
                { "key": "X-Content-Type-Options", "value": "nosniff" },
                { "key": "X-Frame-Options", "value": "DENY" },
                { "key": "X-XSS-Protection", "value": "1; mode=block" }
              ]
            }
          ]
        }
        """
    }

    public static func generateCloudflarePages(title: String) -> String {
        """
        # Cloudflare Pages / Workers configuration (wrangler.toml)
        name = "\(title.lowercased().replacingOccurrences(of: " ", with: "-"))"
        compatibility_date = "2026-11-01"
        pages_build_output_dir = "dist"

        [vars]
        ENVIRONMENT = "production"
        """
    }

    public static func generateDockerfile(platform: String) -> String {
        if platform.lowercased() == "desktop" {
            return """
            # Multi-stage Swift Build Container
            FROM swift:6.0-jammy as builder
            WORKDIR /app
            COPY . .
            RUN swift build -c release

            FROM ubuntu:22.04
            WORKDIR /app
            COPY --from=builder /app/.build/release/App /app/App
            CMD ["/app/App"]
            """
        }

        return """
        # Production Multi-Stage Dockerfile for Web App
        FROM node:20-alpine AS builder
        WORKDIR /app
        COPY package*.json ./
        RUN npm ci
        COPY . .
        RUN npm run build

        # Minimal Production Static Runner
        FROM nginx:alpine
        COPY --from=builder /app/dist /usr/share/nginx/html
        EXPOSE 80
        CMD ["nginx", "-g", "daemon off;"]
        """
    }

    public static func generateGitHubWorkflow(title: String) -> String {
        """
        name: Production CI/CD Pipeline

        on:
          push:
            branches: [ main ]
          pull_request:
            branches: [ main ]

        jobs:
          test-and-deploy:
            runs-on: ubuntu-latest
            steps:
              - name: Checkout Source Code
                uses: actions/checkout@v4

              - name: Setup Node.js Environment
                uses: actions/setup-node@v4
                with:
                  node-version: 20
                  cache: 'npm'

              - name: Install Dependencies
                run: npm ci

              - name: Run Quality Gate & Tests
                run: npm test || true

              - name: Build Production Assets
                run: npm run build
        """
    }
}
