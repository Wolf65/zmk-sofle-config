# --- Настройки ---
WORKFLOW      = build.yml
ARTIFACT_NAME = firmware
DEST_DIR      = ./build_output

# Получаем ID, SHA, Сообщение и Дату (UTC) через разделитель |
GET_RUN_DATA = gh run list --workflow $(WORKFLOW) --status success --limit 1 --json databaseId,headSha,displayTitle,createdAt \
	--jq 'if length > 0 then .[0] | "\(.databaseId)|\(.headSha[0:7])|\(.displayTitle)|\(.createdAt)" else empty end'

.PHONY: help download-fw info clean default
# --- Команда по умолчанию ---
default: help

## info: Информация о последнем билде
info:
	@echo "🔍 Запрос данных из GitHub..."
	@RAW_DATA=$$($(GET_RUN_DATA)); \
	if [ -z "$$RAW_DATA" ]; then echo "❌ Ошибка: Успешных запусков не найдено."; exit 1; fi; \
	ID=$$(echo $$RAW_DATA | cut -d'|' -f1); \
	SHA=$$(echo $$RAW_DATA | cut -d'|' -f2); \
	MSG=$$(echo $$RAW_DATA | cut -d'|' -f3); \
	DATE_UTC=$$(echo $$RAW_DATA | cut -d'|' -f4); \
	printf "SHA:   %s\nMSG:   %s\nDATE:  %s\n" "$$SHA" "$$MSG" "$$DATE_UTC"

## download-fw: Скачать последний успешный артефакт
download-fw: clean
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

## clean: Очистить содержимое папки билда
clean:
	@echo "🧹 Очистка содержимого $(DEST_DIR)..."
	@mkdir -p $(DEST_DIR)
	@find $(DEST_DIR) -mindepth 1 -delete 2>/dev/null || true

## help: Показать справку
help:
	@echo "\n Доступные команды:"
	@sed -n 's/^[[:space:]]*##//p' $(MAKEFILE_LIST) | column -t -s ':' |  sed -e 's/^/ /'
	@echo ""
