#!/bin/bash

# Проверка наличия необходимых переменных окружения
if [ -z "$GITLAB_URL" ] || [ -z "$GITLAB_TOKEN" ]; then
    echo "Ошибка: Необходимо установить переменные окружения GITLAB_URL и GITLAB_TOKEN"
    echo "Пример:"
    echo "export GITLAB_URL='https://gl.webomitorx.ru'"
    echo "export GITLAB_TOKEN='ваш_access_token'"
    exit 1
fi

# Проверка доступности jq
if ! command -v jq &> /dev/null; then
    echo "Ошибка: jq не установлен. Установите его командой:"
    echo "sudo apt-get install jq (для Ubuntu/Debian)"
    exit 1
fi

# Временная директория для клонирования репозиториев
TEMP_DIR=$(mktemp -d)
echo "Временная директория: $TEMP_DIR"

# Файл для сохранения результатов
RESULTS_FILE="$TEMP_DIR/keycloak_repos_results.txt"
echo "Проверка репозиториев на наличие настроек Keycloak..." > "$RESULTS_FILE"

# Получение списка проектов из GitLab
echo "Получение списка репозиториев..."
PROJECTS_URL="${GITLAB_URL}/api/v4/projects?per_page=100"
PROJECTS=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$PROJECTS_URL")

# Проверка, есть ли ошибки в ответе
if echo "$PROJECTS" | jq -e '.message' >/dev/null 2>&1; then
    echo "Ошибка при получении списка проектов:"
    echo "$PROJECTS" | jq -r '.message'
    exit 1
fi

# Подсчет общего количества проектов
TOTAL_PROJECTS=$(echo "$PROJECTS" | jq -r 'length')
echo "Найдено проектов: $TOTAL_PROJECTS"

# Проход по каждому проекту
for i in $(seq 0 $((TOTAL_PROJECTS - 1))); do
    PROJECT_NAME=$(echo "$PROJECTS" | jq -r ".[$i].name")
    PROJECT_URL=$(echo "$PROJECTS" | jq -r ".[$i].http_url_to_repo")
    PROJECT_ID=$(echo "$PROJECTS" | jq -r ".[$i].id")
    
    echo "Проверка репозитория: $PROJECT_NAME"
    
    # Клонирование репозитория
    REPO_DIR="$TEMP_DIR/$PROJECT_NAME"
    if git clone "https://oauth2:$GITLAB_TOKEN@$(echo $PROJECT_URL | sed 's|https://||')" "$REPO_DIR" &>/dev/null; then
        echo "  - Репозиторий успешно клонирован"
        
        # Поиск файлов, содержащих ключевые слова, связанные с Keycloak
        KEYCLOAK_FILES=$(find "$REPO_DIR" -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.xml" -o -name "*.properties" -o -name "*.env" -o -name "*.conf" -o -name "*.config" -o -name "*.js" -o -name "*.ts" -o -name "*.java" -o -name "*.py" -o -name "*.go" -o -name "*.sh" \) -exec grep -l -i -E "keycloak|auth-server-url|realms|realm|client-id|client-secret|authentication|authorization|oidc|oauth|sso|identity|login|logout|token|access-token|refresh-token" {} \; 2>/dev/null | head -20)
        
        if [ -n "$KEYCLOAK_FILES" ]; then
            echo "  - Найдены файлы с настройками Keycloak:" >> "$RESULTS_FILE"
            echo "Репозиторий: $PROJECT_NAME (ID: $PROJECT_ID)" >> "$RESULTS_FILE"
            echo "URL: $PROJECT_URL" >> "$RESULTS_FILE"
            
            while IFS= read -r file; do
                RELATIVE_FILE=$(echo "$file" | sed "s|$REPO_DIR/||")
                echo "  - $RELATIVE_FILE" >> "$RESULTS_FILE"
                
                # Показать строки с ключевыми словами для подтверждения
                grep -i -n -E "keycloak|auth-server-url|realms|realm|client-id|client-secret|authentication|authorization|oidc|oauth|sso|identity|login|logout|token|access-token|refresh-token" "$file" 2>/dev/null | head -5 | while read -r line_num_content; do
                    echo "    $line_num_content" >> "$RESULTS_FILE"
                done
                echo "" >> "$RESULTS_FILE"
            done <<< "$KEYCLOAK_FILES"
            
            echo "    Репозиторий $PROJECT_NAME содержит настройки Keycloak"
        else
            echo "  - Настройки Keycloak не найдены"
        fi
    else
        echo "  - Не удалось клонировать репозиторий"
    fi
    
    # Удаление клонированного репозитория для экономии места
    if [ -d "$REPO_DIR" ]; then
        rm -rf "$REPO_DIR"
    fi
done

echo ""
echo "Поиск завершен."
echo "Результаты сохранены в: $RESULTS_FILE"
echo ""
echo "Репозитории с настройками Keycloak:"
echo "====================================="

if [ -s "$RESULTS_FILE" ]; then
    cat "$RESULTS_FILE"
else
    echo "Настройки Keycloak не найдены ни в одном репозитории."
fi

# Очистка временной директории
rm -rf "$TEMP_DIR"