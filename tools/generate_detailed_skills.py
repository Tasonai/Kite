#!/usr/bin/env python3
import os, glob, re, sys

DIRS = [
    "/Users/tasonai/.gemini/config/skills",
    "/Users/tasonai/.gemini/config/plugins",
    "/Users/tasonai/.gemini/antigravity/builtin/skills"
]

disk_skills = {}
for d in DIRS:
    for f in glob.glob(d + "/**/SKILL.md", recursive=True):
        p_name = os.path.basename(os.path.dirname(f))
        norm_name = p_name.replace("_", "-").lower()
        disk_skills[norm_name] = f
        try:
            with open(f, "r", encoding="utf-8", errors="ignore") as fh:
                head = fh.read(800)
                m = re.search(r'^name:\s*["\']?([^"\'\n]+)', head, re.MULTILINE)
                if m:
                    yaml_name = m.group(1).strip().replace("_", "-").lower()
                    disk_skills[yaml_name] = f
        except:
            pass

def clean_no_emoji(text):
    if not text: return ""
    text = re.sub(r'[\U00010000-\U0010ffff]|[\u2600-\u27bf]|[\u2300-\u23ff]|[\u2b50-\u2b55]|[\u203c-\u2049]|[\u2190-\u21ff]', '', text)
    text = re.sub(r'[ \t]+', ' ', text)
    return text.strip()

def escape_str(s):
    if not s: return ""
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')

# Read existing SkillsData.swift
with open("/Users/tasonai/Developer/Kite/Sources/KiteKit/SkillsData.swift", "r") as f:
    text = f.read()

chunks = text.split("AntigravitySkillInfo(")[1:]
parsed_skills = []

for c in chunks:
    m_id = re.search(r'id:\s*"([^"]+)"', c)
    m_name = re.search(r'name:\s*"([^"]+)"', c)
    m_cmd = re.search(r'command:\s*"([^"]+)"', c)
    m_cat = re.search(r'category:\s*"([^"]+)"', c)
    m_sum = re.search(r'summary:\s*"([^"]+)"', c)
    m_desc = re.search(r'description:\s*"([^"]+)"', c)
    m_plugin = re.search(r'pluginId:\s*(nil|"[^"]+")', c)
    m_trigs = re.search(r'triggers:\s*\[([^\]]*)\]', c)
    m_princ = re.search(r'principles:\s*\[([^\]]*)\]', c)
    m_core = re.search(r'isCore:\s*(true|false)', c)
    
    if m_id and m_name:
        sid = m_id.group(1)
        name = m_name.group(1)
        cmd = f"/{sid}"
        cat = m_cat.group(1) if m_cat else "Система и ядро Antigravity"
        summary = m_sum.group(1) if m_sum else ""
        desc = m_desc.group(1) if m_desc else ""
        plugin_id = None if not m_plugin or m_plugin.group(1) == "nil" else m_plugin.group(1).strip('"')
        triggers = [t.strip().strip('"') for t in m_trigs.group(1).split(",") if t.strip()] if m_trigs else [sid]
        principles = [p.strip().strip('"') for p in m_princ.group(1).split(",") if p.strip()] if m_princ else []
        is_core = m_core.group(1) == "true" if m_core else False
        
        parsed_skills.append({
            "id": sid,
            "name": name,
            "command": cmd,
            "category": cat,
            "summary": summary,
            "description": desc,
            "plugin_id": plugin_id,
            "triggers": triggers,
            "principles": principles,
            "is_core": is_core
        })

print(f"Loaded {len(parsed_skills)} skills from Swift repository.")

# Category-aware translations and prompt helpers
PROMPT_TEMPLATES = {
    "Стили и эстетика (Awesome Design)": "Примени дизайн-систему {name} к экрану: настрой палитру, типографику, сетку и компоненты в соответствии с дизайн-манифестом.",
    "Промпты и спецификации": "Скомпилируй эталонную спецификацию промпта по стандарту {name}: определи структуру страницы, дизайн-токены и ключевые ограничения.",
    "UI/UX, Анимации и Полишинг": "Проведи аудит и полишинг UI по методике {name}: настрой плавные микровзаимодействия sub-250ms, проверь кольца фокуса и исключи сдвиги верстки.",
    "Инженерия Superpowers": "Активируй инженерный процесс {name}: выполни строгий анализ требований, напиши спецификацию и следуй дисциплинированному рабочему процессу.",
    "GSD Управление и Планирование": "Выполни этап управления проектом с помощью {name}: структурируй задачи, проверь зависимости и сформируй дорожную карту.",
    "Vercel, Cloud & Edge": "Настрой облачную архитектуру с помощью {name}: оптимизируй серверные функции, кэширование, маршрутизацию и параметры окружения.",
    "Apple, macOS и iOS": "Реализуй нативные компоненты с помощью {name}: следуй Apple Human Interface Guidelines, используй SwiftUI, SwiftData и правильные отступы 8pt.",
    "Windows 11 и WinUI 3": "Разработай нативный интерфейс по методологии {name}: используй сетку 4 epx, материал Mica, тему Windows 11 и Segoe Fluent Icons.",
    "Дизайн-платформы (Figma & Canva)": "Синхронизируй проект с платформой через {name}: извлеки компоненты, проверь соответствие бренд-киту и экспортируй ассеты.",
    "Google Stitch & Инструменты AI": "Сгенерируй код и дизайн-систему через {name}: обеспечь чистоту компонентов, отсутствие slop и семантическую разметку.",
    "Google Firebase и Бэкенд": "Настрой бэкенд-инфраструктуру через {name}: авторизацию, Firestore Security Rules, облачные функции и AI Logic.",
    "Flutter & Мобильная разработка": "Построй адаптивный мобильный интерфейс через {name}: настрой архитектуру UI/Logic/Data, верстку и валидацию состояния.",
    "Качество, a11y и DevTools": "Проведи глубокий аудит качества через {name}: замерь производительность, проверь доступность WCAG 2.2 AA и устрани ошибки.",
    "Система и ядро Antigravity": "Используй системный инструмент {name} для автоматизации задач агента, управления сессиями и расширения среды.",
    "Анализ кода и Реверс-инжиниринг": "Выполни декомпиляцию и статический анализ архитектуры через {name}: извлеки символы, исследуй потоки данных и восстанови граф зависимостей."
}

def generate_rich_skill_data(s):
    sid = s["id"]
    norm_id = sid.replace("_", "-").lower()
    fpath = disk_skills.get(norm_id)
    
    yaml_desc = ""
    headings = []
    clean_pars = []
    clean_bullets = []
    
    if fpath and os.path.exists(fpath):
        with open(fpath, "r", encoding="utf-8", errors="ignore") as fh:
            raw = fh.read()
            
        if raw.startswith("---"):
            parts = raw.split("---", 2)
            if len(parts) >= 3:
                raw_meta = parts[1]
                body = parts[2].strip()
                m = re.search(r'description:\s*(.+?)(?=\n[a-zA-Z0-9_-]+:|\Z)', raw_meta, re.DOTALL)
                if m:
                    yaml_desc = clean_no_emoji(re.sub(r'\s+', ' ', m.group(1).strip().strip('"\'')))
        else:
            body = raw
            
        clean_body = re.sub(r'<!--.*?-->', '', body, flags=re.DOTALL)
        clean_body = re.sub(r'```.*?```', '', clean_body, flags=re.DOTALL)
        
        headings = [clean_no_emoji(h.strip()) for h in re.findall(r'^#{1,3}\s+(.+)$', clean_body, re.MULTILINE) if len(h.strip()) > 3]
        
        raw_bullets = re.findall(r'^[*-]\s+(.+)$', clean_body, re.MULTILINE)
        for b in raw_bullets:
            cb = clean_no_emoji(re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', b))
            if 20 <= len(cb) <= 130 and not cb.startswith('http'):
                clean_bullets.append(cb)
                
        raw_pars = [clean_no_emoji(p) for p in re.split(r'\n\s*\n', clean_body) if p.strip()]
        clean_pars = [p for p in raw_pars if len(p) > 50 and not p.startswith('#') and not p.startswith('---')]

    # 1. Summary
    orig_summary = clean_no_emoji(s["summary"])
    if yaml_desc and len(yaml_desc) > 25:
        summary = yaml_desc
    else:
        summary = orig_summary if orig_summary else f"Инструмент {s['name']} для экосистемы Antigravity."
        
    # If summary contains prefix like "Качество и диагностика:", strip redundant prefix
    if ":" in summary and len(summary.split(":")[0]) < 30:
        summary = summary.split(":", 1)[1].strip()

    # 2. Detailed Description (3 comprehensive paragraphs)
    cat = s["category"]
    cat_desc = {
        "Стили и эстетика (Awesome Design)": "Визуальная дизайн-система и стилистический стандарт интерфейса. Предопределяет цветовую гармонию, типографику, пропорции карточек, геометрию элементов и правила контрастности, исключая шаблонный и безликий дизайн.",
        "Промпты и спецификации": "Архитектурный генератор и транслятор спецификаций. Превращает абстрактные или краткие формулировки задач в структурированные технические контракты с точными требованиями и структурой страниц.",
        "UI/UX, Анимации и Полишинг": "Инструмент полишинга интерфейса и микроинтеракций. Обеспечивает физику тактильного отклика, пружинные анимации sub-250ms, плавные переходы между состояниями и строгое соответствие принципам Emil Kowalski и Apple HIG.",
        "Инженерия Superpowers": "Дисциплинированная инженерная методология разработки ПО. Включает строгие фазы формулирования требований, Test-Driven Development (TDD), систематический поиск первопричин багов и координацию работы субагентов.",
        "GSD Управление и Планирование": "Модуль фазового управления и планирования GSD (Get Shit Done). Позволяет декомпозировать сложные проекты на атомарные шаги, валидировать риски, строить граф зависимостей и сопровождать реализацию.",
        "Vercel, Cloud & Edge": "Специализированный облачный модуль для инфраструктуры Vercel. Обеспечивает настройку Vercel AI SDK, конфигурацию CDN кэширования, управление переменными окружения, защиту деплоев и развертывание MicroVM Sandbox.",
        "Apple, macOS и iOS": "Инженерный модуль нативной разработки под платформы Apple. Реализует паттерны SwiftUI, хранилище SwiftData, меню MenuBar, поддержку AppKit/UIKit и навигационные паттерны Apple Human Interface Guidelines.",
        "Windows 11 и WinUI 3": "Инженерный модуль создания нативных приложений под Windows 11 по методологии BAWA. Использует WinUI 3, сетку 4 epx, материал Mica, Segoe Fluent Icons и локальное SQLite хранилище с WAL-журналированием.",
        "Дизайн-платформы (Figma & Canva)": "Двусторонний интегратор с дизайн-платформами. Позволяет связывать токены макетов с кодовой базой, конвертировать компоненты Figma/Canva в нативный код и валидировать верстку против дизайн-системы.",
        "Google Stitch & Инструменты AI": "Инструментарий генерации интерфейсов через Google Stitch AI. Создает семантические спецификации DESIGN.md, синтезирует React/Vite и WinUI дашборды, формирует чистую архитектуру компонентов.",
        "Google Firebase и Бэкенд": "Полностековый облачный бэкенд Google Firebase. Настраивает Firebase Auth, правила безопасности Firestore Security Rules, облачные функции и интеграцию с моделями Gemini AI Logic.",
        "Flutter & Мобильная разработка": "Фреймворк мобильной и кроссплатформенной разработки Flutter & Dart. Организует трехслойную архитектуру UI/Logic/Data, адаптивные сетки LayoutBuilder, интерактивные превью и сериализацию данных.",
        "Качество, a11y и DevTools": "Комплекс тестирования, аудита доступности и профилирования. Проверяет доступность интерфейсов по стандарту WCAG 2.2 AA, инспектирует DOM через Chrome DevTools MCP, замеряет метрики Core Web Vitals.",
        "Система и ядро Antigravity": "Системные компоненты платформы Antigravity. Обеспечивают управление жизненным циклом агентов, фоновые фоновые задачи, синхронизацию сессий и интеграцию через протокол MCP.",
        "Анализ кода и Реверс-инжиниринг": "Продвинутый аналитический движок реверс-инжиниринга и анализа бинарных артефактов. Предоставляет инструменты дизассемблирования, трассировки вызовов, исследования структур данных и зависимостей."
    }.get(cat, "Специализированный инструмент платформы Antigravity для расширения возможностей автономных агентов и инженеров.")

    # Paragraph 1: Overview & Mission
    p1 = f"{summary} {cat_desc}"
    
    # Paragraph 2: Technical Workflow
    if clean_pars:
        chosen_par = clean_pars[0]
        # Translate or clean if English
        p2 = f"В процессе работы навык проводит глубокий анализ контекста: {chosen_par}"
    else:
        p2 = f"При вызове навыка агент инициализирует специализированный контекст, проводит статический анализ целевых файлов, проверяет проектные соглашения и формулирует решение в строгом соответствии с инженерными директивами экосистемы."

    # Paragraph 3: Deliverables & Quality Standards
    p3 = "Выходные результаты включают готовый код, обновленную спецификацию, проверенные тесты и структурированные рекомендации. Гарантируется соблюдение принципов надежности, чистота зависимостей, отсутствие регрессий и нулевое использование визуального шума (Zero Slop)."
    
    detailed_desc = f"{p1}\n\n{p2}\n\n{p3}"

    # 3. When To Use
    when_to_use = f"Используйте скилл при необходимости решения задач в категории «{cat}»: для проектирования, рефакторинга, генерации кода, настройки конфигурации или верификации качества по стандарту {s['name']}."
    if "Use when" in summary or "use when" in summary:
        m_uw = re.search(r'[Uu]se when\s+(.+)', summary)
        if m_uw:
            when_to_use = f"Активируйте в следующих случаях: {m_uw.group(1).rstrip('.')}."

    # 4. Capabilities (3-5 items)
    capabilities = []
    if clean_bullets:
        for b in clean_bullets[:4]:
            capabilities.append(b)
    if len(capabilities) < 3:
        if headings:
            for h in headings[:3]:
                if len(h) < 60 and h.lower() not in ["overview", "prerequisites", "when to use", "iron law"]:
                    capabilities.append(h)
    if len(capabilities) < 3:
        capabilities.extend([
            f"Автоматизированный анализ и интеграция по стандарту {s['name']}",
            "Генерация типобезопасного кода и проектных артефактов",
            "Валидация ограничений и предотвращение регрессий"
        ])
    capabilities = capabilities[:4]

    # 5. Example Prompt
    prompt_tpl = PROMPT_TEMPLATES.get(cat, "Активируй скилл {name} для выполнения комплексного анализа и реализации задачи.")
    example_prompt = f"/{s['name']} " + prompt_tpl.format(name=s['name'])

    # 6. Principles (real principles without emoji)
    principles = s["principles"]
    if not principles or len(principles) < 3:
        principles = [
            "Дисциплинированная пошаговая разработка",
            "Строгое соответствие техническому контракту",
            "Zero AI Slop и чистая архитектура"
        ]

    # 7. Triggers
    triggers = s["triggers"]
    if sid not in triggers:
        triggers.insert(0, sid)
    if s["name"] not in triggers:
        triggers.append(s["name"])

    return {
        "id": sid,
        "name": s["name"],
        "command": s["command"],
        "category": cat,
        "summary": summary,
        "description": detailed_desc,
        "plugin_id": s["plugin_id"],
        "triggers": triggers,
        "principles": principles,
        "is_core": s["is_core"],
        "when_to_use": when_to_use,
        "capabilities": capabilities,
        "example_prompt": example_prompt
    }

print("Synthesizing rich skill data for all 355 skills...")
rich_skills = [generate_rich_skill_data(s) for s in parsed_skills]
print(f"Generated rich data for {len(rich_skills)} skills.")

# Verify ZERO EMOJIS in generated data
for item in rich_skills:
    for field in ["summary", "description", "when_to_use", "example_prompt"]:
        text = item[field]
        emojis = [c for c in text if (0x1F300 <= ord(c) <= 0x1FAFF) or (0x2600 <= ord(c) <= 0x27BF)]
        if emojis:
            print(f"EMOJI VIOLATION in {item['id']} field {field}: {emojis}")
            sys.exit(1)

print("ZERO EMOJIS VERIFIED ACROSS ALL GENERATED SKILLS!")

# Generate Swift file
swift_out = """import Foundation

public struct AntigravitySkillInfo: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let command: String
    public let category: String
    public let summary: String
    public let description: String
    public let pluginId: String?
    public let triggers: [String]
    public let principles: [String]
    public let isCore: Bool
    public let whenToUse: String
    public let examplePrompt: String
    public let capabilities: [String]

    public init(
        id: String,
        name: String,
        command: String,
        category: String,
        summary: String,
        description: String,
        pluginId: String? = nil,
        triggers: [String] = [],
        principles: [String] = [],
        isCore: Bool = false,
        whenToUse: String = "",
        examplePrompt: String = "",
        capabilities: [String] = []
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.category = category
        self.summary = summary
        self.description = description
        self.pluginId = pluginId
        self.triggers = triggers
        self.principles = principles
        self.isCore = isCore
        self.whenToUse = whenToUse
        self.examplePrompt = examplePrompt
        self.capabilities = capabilities
    }
}

public enum SkillsRepository {
    public static let curated: [AntigravitySkillInfo] = [
"""

for item in rich_skills:
    plugin_val = f'"{item["plugin_id"]}"' if item["plugin_id"] else "nil"
    trig_vals = ", ".join([f'"{escape_str(t)}"' for t in item["triggers"]])
    princ_vals = ", ".join([f'"{escape_str(p)}"' for p in item["principles"]])
    cap_vals = ", ".join([f'"{escape_str(c)}"' for c in item["capabilities"]])
    core_val = "true" if item["is_core"] else "false"
    
    swift_out += f"""        AntigravitySkillInfo(
            id: "{item['id']}",
            name: "{item['name']}",
            command: "{item['command']}",
            category: "{escape_str(item['category'])}",
            summary: "{escape_str(item['summary'])}",
            description: "{escape_str(item['description'])}",
            pluginId: {plugin_val},
            triggers: [{trig_vals}],
            principles: [{princ_vals}],
            isCore: {core_val},
            whenToUse: "{escape_str(item['when_to_use'])}",
            examplePrompt: "{escape_str(item['example_prompt'])}",
            capabilities: [{cap_vals}]
        ),
"""

swift_out += """    ]
}
"""

with open("/Users/tasonai/Developer/Kite/Sources/KiteKit/SkillsData.swift", "w", encoding="utf-8") as f:
    f.write(swift_out)
print("Updated /Users/tasonai/Developer/Kite/Sources/KiteKit/SkillsData.swift")

# Generate C# file for KiteWin
cs_out = """namespace KiteWin.Core;

public record AntigravitySkillInfo(
    string Name,
    string Category,
    string Summary,
    string Description,
    string? PluginId = null,
    bool IsCore = false,
    string WhenToUse = "",
    string ExamplePrompt = "",
    string[]? Capabilities = null,
    string[]? Principles = null,
    string[]? Triggers = null
);

public static class SkillsRepository
{
    public static readonly AntigravityPluginInfo[] Plugins =
    [
        new("bama", "Build Any Mac App (BAMA)", "Apple & macOS", "bama", "1.2.0",
            "Комплексный плагин для проектирования и сборки нативных macOS приложений на SwiftUI и SwiftData.", 5,
            ["bama", "mac-design", "new-mac-app", "swift-swiftui", "test-mac-app"], null, "bama", "\\uE7F4"),

        new("bawa", "Build Any Windows App (BAWA)", "Windows & WinUI", "bawa", "1.0.0",
            "Разработка современных нативных приложений под Windows 11 с использованием C#, WinUI 3 и Fluent Design.", 22,
            ["agent-cli", "app-brief", "app-icon", "bawa", "build-and-verify", "clone", "csharp-winui", "design-from-app", "design-kit", "design-system", "distribute", "improve-architecture", "improve-loop", "layout-grid", "new-windows-app", "os-integrations", "performance", "research", "test-windows-app", "user-stories", "ux-design", "windows-design"], null, "bawa", "\\uE7F4"),

        new("canva", "Canva Design & Export MCP", "Дизайн-платформы", "Canva", "2.1.0",
            "Интеграция с платформой Canva через MCP: создание макетов, ресайз для соцсетей, бренд-киты и экспорт.", 11,
            ["canva-brand-check", "canva-bulk-create", "canva-edit-design", "canva-resize-for-social-media"], "canva_canva", null, "\\uE790"),

        new("chrome-devtools-plugin", "Chrome DevTools & a11y", "Тестирование и DevTools", "Google Chrome", "1.4.0",
            "Профилировщик Chrome через MCP: замеры Core Web Vitals, аудит доступности WCAG, поиск утечек памяти.", 6,
            ["a11y-debugging", "chrome-devtools", "cookie-debugging", "memory-leak-debugging", "troubleshooting"], "chrome-devtools", null, "\\uE774"),

        new("coderabbit", "CodeRabbit AI Review & Autofix", "Код-ревью и аудит", "CodeRabbit", "0.9.5",
            "Глубокий анализ исходного кода, аудит безопасности пул-реквестов и автоматическое применение исправлений.", 2,
            ["autofix", "code-review"], null, "coderabbit", "\\uE896"),

        new("figma", "Figma Design to Code & Connect", "Дизайн-системы", "Figma", "3.0.0",
            "Двусторонняя интеграция с Figma: конвертация фреймов в код (React, WinUI, SwiftUI), FigJam диаграммы и токены.", 18,
            ["figma-code-connect", "figma-create-new-file", "figma-design-to-code", "figma-generate-diagram", "figma-shaders", "figma-swiftui", "figma-use"], "figma_figma", null, "\\uE790"),

        new("firebase", "Google Firebase Full-Stack", "Бэкенд и облачные сервисы", "Google Firebase", "2.2.0",
            "Облачный бэкенд Google Firebase: Firebase Auth, Firestore Security Rules, Gemini AI Logic, App Hosting.", 13,
            ["firebase-ai-logic-basics", "firebase-auth-basics", "firebase-firestore", "firebase-security-rules-auditor", "firestore-rules-creation"], null, "firebase", "\\uE753"),

        new("flutter", "Flutter & Dart Mobile SDK", "Мобильная разработка", "Google Flutter Team", "3.24.0",
            "Инструменты разработки кроссплатформенных приложений на Flutter и Dart: адаптивная верстка, превью виджетов.", 25,
            ["flutter-add-widget-preview", "flutter-apply-architecture-best-practices", "flutter-build-responsive-layout", "flutter-fix-layout-issues"], null, "flutter", "\\uE8EA"),

        new("gemini-api", "Google Gemini API & Docs", "Искусственный интеллект", "Google Gemini Team", "1.5.0",
            "Официальная интеграция с семейством моделей Google Gemini 2.5 Flash, Pro и Live Audio API через SDK.", 3,
            ["gemini-api-dev", "gemini-live-api-dev", "gemini-omni-flash-api"], "gemini-api_gemini-api-docs", null, "\\uE945"),

        new("mobbin", "Mobbin UI/UX Real-World References", "Дизайн-референсы", "Mobbin", "2.0.0",
            "Интеллектуальный поиск по каталогу 600,000+ скриншотов и пользовательских сценариев реальных топовых продуктов.", 4,
            ["best-practices", "plain-writing", "redesign-screen", "search"], "mobbin_mobbin", null, "\\uEB9F"),

        new("stitch-build", "Google Stitch Code Generation", "Инструменты Stitch AI", "Google Stitch Team", "1.0.0",
            "Генерация чистого TypeScript/React и WinUI C# кода, дашбордов TanStack Query и Remotion видео из Stitch-макетов.", 5,
            ["react-vite-dashboard", "remotion", "shadcn-ui", "stitch::react-components", "stitch::react-native"], "stitch", null, "\\uE70F"),

        new("stitch-design", "Google Stitch Design System", "Инструменты Stitch AI", "Google Stitch Team", "1.0.0",
            "Управление дизайн-системами в Stitch: конвертация кода в макеты, извлечение static HTML и синхронизация экранов.", 6,
            ["stitch::code-to-design", "stitch::extract-design-md", "stitch::generate-design", "stitch::manage-design-system"], "stitch", null, "\\uE790"),

        new("stitch-utilities", "Google Stitch Utilities & Prompts", "Инструменты Stitch AI", "Google Stitch Team", "1.0.0",
            "Утилиты для авторов Stitch: улучшение UI-промптов, синтез конституции сайта SITE.md и автономный цикл генерации.", 5,
            ["design-md", "enhance-prompt", "site-md", "stitch-loop", "taste-design"], "stitch", null, "\\uE713"),

        new("supabase", "Supabase PostgreSQL & Edge MCP", "Бэкенд и базы данных", "Supabase", "2.0.0",
            "Полное управление Supabase из среды Antigravity: SQL-запросы, RLS политики безопасности, миграции, Edge Functions.", 2,
            ["supabase", "supabase-postgres-best-practices"], "supabase_mcp", null, "\\uE753"),

        new("superpowers", "Superpowers Engineering System", "Инженерные суперсилы", "Antigravity Superpowers", "2.0.0",
            "Дисциплинированная методология: дивергентный брейншторминг, Test-Driven Development (TDD), дебаггинг и субагенты.", 15,
            ["brainstorming", "dispatching-parallel-agents", "executing-plans", "subagent-driven-development", "systematic-debugging", "test-driven-development", "writing-plans"], null, null, "\\uE9D9"),

        new("vercel-plugin", "Vercel Deployment & AI Cloud", "Vercel, Cloud & Edge", "Vercel", "3.2.0",
            "Облачный стек Vercel: Vercel AI SDK, развертывание проектов, превью-URL, KV/Blob хранилище, MicroVM Sandbox.", 38,
            ["ai-sdk", "build-agents", "deployments-cicd", "domains", "env-vars", "runtime-cache", "vercel-agent", "vercel-sandbox", "workflow"], null, "vercel", "\\uE753")
    ];

    public static readonly AntigravitySkillInfo[] CuratedSkills =
    [
"""

for item in rich_skills:
    plugin_val = f'"{item["plugin_id"]}"' if item["plugin_id"] else "null"
    core_val = "true" if item["is_core"] else "false"
    trig_vals = ", ".join([f'"{escape_str(t)}"' for t in item["triggers"]])
    princ_vals = ", ".join([f'"{escape_str(p)}"' for p in item["principles"]])
    cap_vals = ", ".join([f'"{escape_str(c)}"' for c in item["capabilities"]])
    
    cs_out += f"""        new("{item['name']}", "{escape_str(item['category'])}",
            "{escape_str(item['summary'])}",
            "{escape_str(item['description'])}",
            {plugin_val}, {core_val},
            "{escape_str(item['when_to_use'])}",
            "{escape_str(item['example_prompt'])}",
            [{cap_vals}],
            [{princ_vals}],
            [{trig_vals}]),
"""

cs_out += """    ];
}
"""

with open("/Users/tasonai/Developer/KiteWindows/src/KiteWin.Core/SkillsData.cs", "w", encoding="utf-8") as f:
    f.write(cs_out)
print("Updated /Users/tasonai/Developer/KiteWindows/src/KiteWin.Core/SkillsData.cs")

