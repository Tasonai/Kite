import Foundation

public struct EmailTemplateConfig: Identifiable, Sendable, Equatable {
    public var id: String { templateName }
    public var templateName: String
    public var subjectLine: String
    public var recipientCategory: String
    public var dynamicVariables: [String]
    public var previewSnippet: String

    public init(templateName: String, subjectLine: String, recipientCategory: String, dynamicVariables: [String], previewSnippet: String) {
        self.templateName = templateName
        self.subjectLine = subjectLine
        self.recipientCategory = recipientCategory
        self.dynamicVariables = dynamicVariables
        self.previewSnippet = previewSnippet
    }
}

public enum EmailStudio {
    public static var starterTemplates: [EmailTemplateConfig] {
        [
            EmailTemplateConfig(
                templateName: "Welcome & Onboarding",
                subjectLine: "Добро пожаловать в Kite! Начните проектирование",
                recipientCategory: "Новые пользователи",
                dynamicVariables: ["userName", "dashboardUrl", "supportEmail"],
                previewSnippet: "Привет, {{userName}}! Ваше рабочее пространство готово."
            ),
            EmailTemplateConfig(
                templateName: "Team Invite",
                subjectLine: "{{inviterName}} приглашает вас в проект {{projectName}}",
                recipientCategory: "Участники команды",
                dynamicVariables: ["inviterName", "projectName", "inviteAcceptUrl"],
                previewSnippet: "Вам открыт доступ к холсту и спецификациям проекта."
            ),
            EmailTemplateConfig(
                templateName: "Password Reset & Magic Link",
                subjectLine: "Ссылка для входа в ваш аккаунт Kite",
                recipientCategory: "Авторизация",
                dynamicVariables: ["magicLinkUrl", "expireMinutes"],
                previewSnippet: "Нажмите на кнопку ниже, чтобы безопасно войти в систему."
            ),
            EmailTemplateConfig(
                templateName: "Invoice Receipt",
                subjectLine: "Квитанция об оплате тарифа {{planName}}",
                recipientCategory: "Платежи",
                dynamicVariables: ["invoiceId", "amount", "currency", "receiptUrl"],
                previewSnippet: "Платеж успешно проведен. Спасибо за подписку на Kite."
            )
        ]
    }

    public static func generateEmailMarkdown(title: String, templates: [EmailTemplateConfig]) -> String {
        var lines: [String] = [
            "# TRANSACTIONAL EMAIL & NOTIFICATION SPEC: \(title.uppercased())",
            "This specification guides Google DeepMind Antigravity in generating mobile-responsive email templates.",
            "All notification emails MUST be built with React Email / Resend with strict inline styles.",
            ""
        ]

        for (idx, t) in templates.enumerated() {
            lines.append("## \(idx + 1). \(t.templateName)")
            lines.append("- Subject: \"\(t.subjectLine)\"")
            lines.append("- Category: \(t.recipientCategory)")
            lines.append("- Dynamic Variables: `\(t.dynamicVariables.joined(separator: ", "))`")
            lines.append("- Preview Snippet: \"\(t.previewSnippet)\"")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generateReactEmailSnippet(title: String) -> String {
        let lines: [String] = [
            "// emails/WelcomeEmail.tsx",
            "// Responsive transactional email template using @react-email/components",
            "import * as React from 'react';",
            "import { Html, Head, Body, Container, Section, Text, Button, Hr } from '@react-email/components';",
            "",
            "interface WelcomeEmailProps {",
            "  userName: string;",
            "  dashboardUrl: string;",
            "}",
            "",
            "export default function WelcomeEmail({ userName = 'Разработчик', dashboardUrl = 'https://app.example.com' }: WelcomeEmailProps) {",
            "  return (",
            "    <Html>",
            "      <Head />",
            "      <Body style={{ backgroundColor: '#f6f9fc', fontFamily: 'sans-serif' }}>",
            "        <Container style={{ margin: '0 auto', padding: '20px 0 48px', maxWidth: '580px' }}>",
            "          <Section style={{ backgroundColor: '#ffffff', padding: '32px', borderRadius: '8px' }}>",
            "            <Text style={{ fontSize: '20px', fontWeight: 'bold', color: '#1a1a1a' }}>",
            "              Добро пожаловать в \(title)!",
            "            </Text>",
            "            <Text style={{ fontSize: '15px', lineHeight: '24px', color: '#4a4a4a' }}>",
            "              Привет, {userName}! Ваша среда вайбкодинга в Google DeepMind Antigravity настроена и готова к работе.",
            "            </Text>",
            "            <Button href={dashboardUrl} style={{ backgroundColor: '#0066cc', color: '#ffffff', padding: '12px 24px', borderRadius: '6px', fontWeight: '600' }}>",
            "              Перейти в панель управления",
            "            </Button>",
            "            <Hr style={{ borderColor: '#e6ebf1', margin: '24px 0' }} />",
            "            <Text style={{ fontSize: '12px', color: '#8898aa' }}>",
            "              Если вы не регистрировались в сервисе, просто проигнорируйте это письмо.",
            "            </Text>",
            "          </Section>",
            "        </Container>",
            "      </Body>",
            "    </Html>",
            "  );",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(templates: [EmailTemplateConfig]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY EMAIL TEMPLATES DIRECTIVE]",
            "Do NOT send raw unformatted text emails or non-responsive tables.",
            "Render all transactional emails via React Email adhering to these template specs:",
            ""
        ]

        for t in templates {
            lines.append("- [\(t.templateName)]: Subject \"\(t.subjectLine)\", variables [\(t.dynamicVariables.joined(separator: ", "))]")
        }

        lines.append("")
        lines.append("Ensure full compatibility with dark mode in Apple Mail, Gmail, and Outlook.")
        return lines.joined(separator: "\n")
    }
}
