# --- Настройки ---
WORKFLOW      = build.yml
ARTIFACT_NAME = firmware
DEST_DIR      = ./build_output

HELP_COLOR = \033[36m
RESET_COLOR = \033[0m

# Получаем ID, SHA, Сообщение и Дату (UTC) через разделитель |
GET_RUN_DATA = gh run list --workflow $(WORKFLOW) --status success --limit 1 --json databaseId,headSha,displayTitle,createdAt \
	--jq 'if length > 0 then .[0] | "\(.databaseId)|\(.headSha[0:7])|\(.displayTitle)|\(.createdAt)" else empty end'

default: help

.PHONY: info
info: ## Информация о последнем билде
	@echo "🔍 Запрос данных из GitHub..."
	@RAW_DATA=$$($(GET_RUN_DATA)); \
	if [ -z "$$RAW_DATA" ]; then echo "❌ Ошибка: Успешных запусков не найдено."; exit 1; fi; \
	ID=$$(echo $$RAW_DATA | cut -d'|' -f1); \
	SHA=$$(echo $$RAW_DATA | cut -d'|' -f2); \
	MSG=$$(echo $$RAW_DATA | cut -d'|' -f3); \
	DATE_UTC=$$(echo $$RAW_DATA | cut -d'|' -f4); \
	printf "SHA:   %s\nMSG:   %s\nDATE:  %s\n" "$$SHA" "$$MSG" "$$DATE_UTC"

.PHONY: download-fw
download-fw: clean ## Скачать последний успешный артефакт
	@RAW_DATA=$$($(GET_RUN_DATA)); \
	if [ -z "$$RAW_DATA" ]; then echo "❌ Ошибка: Успешных запусков не найдено."; exit 1; fi; \
	ID=$$(echo $$RAW_DATA | cut -d'|' -f1); \
	SHA=$$(echo $$RAW_DATA | cut -d'|' -f2); \
	MSG=$$(echo $$RAW_DATA | cut -d'|' -f3); \
	DATE_UTC=$$(echo $$RAW_DATA | cut -d'|' -f4); \
	echo "✅ Найдено для скачивания:"; \
	printf "   [%s] %s\n   Дата: %s\n" "$$SHA" "$$MSG" "$$DATE_UTC"; \
	echo "📥 Загрузка в $(DEST_DIR)..."; \
	gh run download $$ID --name $(ARTIFACT_NAME) --dir $(DEST_DIR); \
	echo "🎉 Готово!"

.PHONY: clear
clean: ## Очистить содержимое папки билда
	@echo "🧹 Очистка содержимого $(DEST_DIR)..."
	@mkdir -p $(DEST_DIR)
	@find $(DEST_DIR) -mindepth 1 -delete 2>/dev/null || true

.PHONY: help
help: ## Показать справку
	@awk -v col="$(HELP_COLOR)" -v res="$(RESET_COLOR)" 'BEGIN { \
		FS = ":.*##"; \
		printf "Использование:\n  make %s<цель>%s\n\nЦели:\n", col, res \
	} \
	/^[a-zA-Z_-]+:.*##/ { \
		count++; \
		targets[count] = $$1; \
		help[$$1] = $$2; \
		if (length($$1) > max_len) max_len = length($$1); \
	} \
	END { \
		for (i = 1; i <= count; i++) { \
			t = targets[i]; \
			printf "  %s%-*s%s  %s\n", col, max_len, t, res, help[t] \
		} \
	}' $(MAKEFILE_LIST)