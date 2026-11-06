import Foundation

public struct FallbackStrategy: Identifiable, Sendable, Equatable {
    public var id: String { scenario }
    public var scenario: String
    public var failureTrigger: String
    public var recoveryAction: String
    public var implementationSnippet: String

    public init(scenario: String, failureTrigger: String, recoveryAction: String, implementationSnippet: String) {
        self.scenario = scenario
        self.failureTrigger = failureTrigger
        self.recoveryAction = recoveryAction
        self.implementationSnippet = implementationSnippet
    }
}

public enum FallbackPlanner {
    public static var starterStrategies: [FallbackStrategy] {
        [
            FallbackStrategy(
                scenario: "Обрыв интернет-соединения",
                failureTrigger: "fetch() throws TypeError / navigator.onLine === false",
                recoveryAction: "Загрузить последний успешный снимок данных из localStorage и показать ненавязчивый индикатор оффлайна.",
                implementationSnippet: """
                try {
                  const res = await fetch('/api/data');
                  const json = await res.json();
                  localStorage.setItem('cached_data', JSON.stringify(json));
                  return json;
                } catch {
                  const cached = localStorage.getItem('cached_data');
                  if (cached) return JSON.parse(cached);
                  throw new Error('Данные недоступны в оффлайне');
                }
                """
            ),
            FallbackStrategy(
                scenario: "Превышение квоты API (HTTP 429)",
                failureTrigger: "res.status === 429 / Gemini API rate limit",
                recoveryAction: "Экспоненциальная задержка (exponential backoff) с таймером обратного отсчета для пользователя.",
                implementationSnippet: """
                if (res.status === 429) {
                  const retryAfter = parseInt(res.headers.get('Retry-After') || '5', 10);
                  await new Promise(r => setTimeout(r, retryAfter * 1000));
                  return fetchWithRetry(url, options, retries - 1);
                }
                """
            ),
            FallbackStrategy(
                scenario: "Крах рендера компонента (White Screen)",
                failureTrigger: "Uncaught React error / undefined property access",
                recoveryAction: "Локальный ErrorBoundary с кнопкой Перезагрузить компонент вместо белого экрана.",
                implementationSnippet: """
                class ErrorBoundary extends React.Component {
                  state = { hasError: false };
                  static getDerivedStateFromError() { return { hasError: true }; }
                  render() {
                    if (this.state.hasError) {
                      return <div className="p-4 border border-red-200 rounded">Произошла ошибка <button onClick={() => this.setState({ hasError: false })}>Повторить</button></div>;
                    }
                    return this.props.children;
                  }
                }
                """
            ),
            FallbackStrategy(
                scenario: "Пустой ответ от сервера (Empty State)",
                failureTrigger: "items.length === 0",
                recoveryAction: "Отобразить карточку Empty State с понятным призывом к действию вместо пустой таблицы.",
                implementationSnippet: """
                if (items.length === 0) {
                  return (
                    <div className="text-center py-12 text-slate-500">
                      <p>Записей пока нет</p>
                      <button onClick={onCreate} className="mt-4 px-4 py-2 bg-indigo-600 text-white rounded">Создать первую</button>
                    </div>
                  );
                }
                """
            )
        ]
    }

    public static func generateFallbacksMarkdown(title: String, strategies: [FallbackStrategy]) -> String {
        var lines: [String] = [
            "# GRACEFUL DEGRADATION & FALLBACK STRATEGY: \(title.uppercased())",
            "This specification mandates resilience patterns for Google DeepMind Antigravity.",
            "All generated code MUST implement the following degradation paths:",
            ""
        ]

        for (idx, s) in strategies.enumerated() {
            lines.append("## \(idx + 1). \(s.scenario)")
            lines.append("- Trigger: `\(s.failureTrigger)`")
            lines.append("- Recovery Action: \(s.recoveryAction)")
            lines.append("- Required Pattern:")
            lines.append("```ts")
            lines.append(s.implementationSnippet)
            lines.append("```")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    public static func generatePromptDirective(strategies: [FallbackStrategy]) -> String {
        var lines: [String] = [
            "[ANTIGRAVITY GRACEFUL DEGRADATION DIRECTIVE]",
            "Do NOT write happy-path only code. Implement mandatory fallbacks for:",
            ""
        ]

        for s in strategies {
            lines.append("- [\(s.scenario)] If `\(s.failureTrigger)` -> \(s.recoveryAction)")
        }

        lines.append("")
        lines.append("Wrap all async operations in try/catch and include offline/empty states.")
        return lines.joined(separator: "\n")
    }
}
