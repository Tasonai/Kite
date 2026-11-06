import Foundation

public enum WebMockupGenerator {
    public static func generateInteractiveHTML(
        title: String,
        concept: String,
        platform: String,
        style: String
    ) -> String {
        let cleanTitle = title.isEmpty ? "Интерактивный черновик" : title
        let cleanConcept = concept.isEmpty ? "Описание концепции и сценария использования." : concept
        let tokens = DesignSystemTokens.resolve(for: style)

        return """
        <!DOCTYPE html>
        <html lang="ru">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(cleanTitle) &bull; Интерактивный эскиз</title>
          <style>
            :root {
              --bg: \(tokens.background);
              --surface: \(tokens.surface);
              --accent: \(tokens.accent);
              --text-primary: \(tokens.textPrimary);
              --text-secondary: \(tokens.textSecondary);
              --border: rgba(140, 140, 140, 0.2);
              --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
              --font-mono: "SF Mono", Menlo, Consolas, monospace;
            }
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              font-family: var(--font-sans);
              background: var(--bg);
              color: var(--text-primary);
              min-height: 100vh;
              display: flex;
              flex-direction: column;
            }
            header {
              height: 56px;
              background: var(--surface);
              border-bottom: 1px solid var(--border);
              display: flex;
              align-items: center;
              justify-content: space-between;
              padding: 0 24px;
              position: sticky;
              top: 0;
            }
            .brand {
              display: flex;
              align-items: center;
              gap: 8px;
              font-weight: 700;
              font-size: 16px;
            }
            .badge {
              font-size: 10px;
              font-family: var(--font-mono);
              padding: 2px 8px;
              border-radius: 9999px;
              background: rgba(59, 130, 246, 0.15);
              color: var(--accent);
              font-weight: 600;
            }
            main {
              flex: 1;
              max-width: 960px;
              width: 100%;
              margin: 0 auto;
              padding: 32px 24px;
            }
            .hero {
              background: var(--surface);
              border: 1px solid var(--border);
              border-radius: 12px;
              padding: 24px;
              margin-bottom: 24px;
            }
            .hero h1 {
              font-size: 24px;
              margin-bottom: 8px;
              letter-spacing: -0.5px;
            }
            .hero p {
              color: var(--text-secondary);
              font-size: 14px;
              line-height: 1.5; // grid: ok css line-height
            }
            .grid {
              display: grid;
              grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
              gap: 16px;
              margin-bottom: 24px;
            }
            .card {
              background: var(--surface);
              border: 1px solid var(--border);
              border-radius: 12px;
              padding: 16px;
              transition: transform 0.15s ease, box-shadow 0.15s ease;
            }
            .card:hover {
              transform: translateY(-2px);
              box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            }
            .card h3 {
              font-size: 15px;
              margin-bottom: 6px;
            }
            .card p {
              font-size: 13px;
              color: var(--text-secondary);
              line-height: 1.4; // grid: ok css line-height
            }
            .interactive-panel {
              background: var(--surface);
              border: 1px solid var(--border);
              border-radius: 12px;
              padding: 20px;
            }
            .input-group {
              display: flex;
              gap: 8px;
              margin-top: 12px;
            }
            input[type="text"] {
              flex: 1;
              padding: 10px 14px;
              border-radius: 8px;
              border: 1px solid var(--border);
              background: var(--bg);
              color: var(--text-primary);
              font-size: 14px;
              outline: none;
            }
            input[type="text"]:focus {
              border-color: var(--accent);
            }
            button.btn-primary {
              padding: 10px 18px;
              background: var(--accent);
              color: #ffffff;
              border: none;
              border-radius: 8px;
              font-weight: 600;
              font-size: 14px;
              cursor: pointer;
              transition: opacity 0.15s ease;
            }
            button.btn-primary:hover {
              opacity: 0.9;
            }
            .item-list {
              margin-top: 16px;
              display: flex;
              flex-direction: column;
              gap: 8px;
            }
            .list-item {
              display: flex;
              align-items: center;
              justify-content: space-between;
              padding: 10px 14px;
              background: var(--bg);
              border-radius: 8px;
              font-size: 14px;
            }
            footer {
              padding: 16px 24px;
              text-align: center;
              font-size: 12px;
              color: var(--text-secondary);
              border-top: 1px solid var(--border);
            }
          </style>
        </head>
        <body>
          <header>
            <div class="brand">
              <span>\(cleanTitle)</span>
              <span class="badge">\(platform)</span>
              <span class="badge">\(style)</span>
            </div>
            <div>
              <span style="font-size: 12px; color: var(--text-secondary);">Интерактивный черновик Kite</span>
            </div>
          </header>

          <main>
            <div class="hero">
              <h1>\(cleanTitle)</h1>
              <p>\(cleanConcept)</p>
            </div>

            <div class="grid">
              <div class="card">
                <h3>1. Основной функционал</h3>
                <p>Ключевое действие выполняется в 1-2 клика с мгновенным откликом и сохранением состояния.</p>
              </div>
              <div class="card">
                <h3>2. Автономность и скорость</h3>
                <p>Все данные работают локально на устройстве без обязательной привязки к серверу.</p>
              </div>
              <div class="card">
                <h3>3. Выверенная эргономика</h3>
                <p>Сетка 4pt/8pt, крупные интерактивные области и клавиатурные шорткаты.</p>
              </div>
            </div>

            <div class="interactive-panel">
              <h3>Проверьте интерактивность прямо сейчас</h3>
              <p style="font-size: 13px; color: var(--text-secondary); margin-top: 4px;">Добавьте тестовую запись, чтобы увидеть поведение списка:</p>
              <div class="input-group">
                <input type="text" id="recordInput" placeholder="Введите название новой задачи или записи...">
                <button class="btn-primary" onclick="addRecord()">Добавить</button>
              </div>

              <div class="item-list" id="recordsList">
                <div class="list-item">
                  <span>Первый шаг: проверка архитектуры в Kite</span>
                  <span class="badge" style="background: rgba(16, 185, 129, 0.15); color: #10B981;">Выполнено</span>
                </div>
              </div>
            </div>
          </main>

          <footer>
            Сгенерировано в Kite &bull; Дизайн-система: \(style) &bull; 100% готов к экспорту в Cursor / Claude
          </footer>

          <script>
            function addRecord() {
              const input = document.getElementById('recordInput');
              const text = input.value.trim();
              if (!text) return;
              const list = document.getElementById('recordsList');
              const item = document.createElement('div');
              item.className = 'list-item';
              item.innerHTML = '<span>' + escapeHtml(text) + '</span><span class="badge">Новое</span>';
              list.appendChild(item);
              input.value = '';
            }
            function escapeHtml(str) {
              return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
            }
            document.getElementById('recordInput').addEventListener('keydown', function(e) {
              if (e.key === 'Enter') addRecord();
            });
          </script>
        </body>
        </html>
        """
    }
}
