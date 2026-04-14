#!/usr/bin/env bash
# @req SCI-TRACE-001
set -euo pipefail

REQUIREMENTS_FILE="requirements.yaml"
SEARCH_DIRS=("charts/" "ansible/")
ERRORS=0

# Извлекаем все валидные ID требований из requirements.yaml
VALID_IDS=$(grep '^\s*- id:' "$REQUIREMENTS_FILE" | awk '{print $3}')

echo "=== Traceability Check ==="
echo "Valid requirement IDs:"
echo "$VALID_IDS"
echo ""

# Собираем все yaml/yml/tpl файлы
FILES=$(find "${SEARCH_DIRS[@]}" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.tpl" \))

UNANNOTATED=()
ORPHAN_REFS=()

for FILE in $FILES; do
  # Проверяем наличие хотя бы одной @req аннотации
  if ! grep -q "@req SCI-" "$FILE"; then
    UNANNOTATED+=("$FILE")
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Извлекаем все referenced IDs из файла
  REFS=$(grep -oE "SCI-[A-Z]+-[0-9]+" "$FILE" || true)

  for REF in $REFS; do
    if ! echo "$VALID_IDS" | grep -qx "$REF"; then
      ORPHAN_REFS+=("$FILE: $REF")
      ERRORS=$((ERRORS + 1))
    fi
  done
done

# Репортим результаты
if [ ${#UNANNOTATED[@]} -gt 0 ]; then
  echo "FAIL — unannotated files (missing @req):"
  for F in "${UNANNOTATED[@]}"; do
    echo "  - $F"
  done
  echo ""
fi

if [ ${#ORPHAN_REFS[@]} -gt 0 ]; then
  echo "FAIL — orphan @req references (ID not in requirements.yaml):"
  for R in "${ORPHAN_REFS[@]}"; do
    echo "  - $R"
  done
  echo ""
fi

if [ $ERRORS -eq 0 ]; then
  echo "PASS — all files annotated, no orphan references"
  exit 0
else
  echo "FAIL — $ERRORS violation(s) found"
  exit 1
fi
