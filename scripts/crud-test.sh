#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3000}"
API="$BASE_URL/api/products"
PID="$(date +%s)"
STATUS=""
BODY=""

request() {
  local method="$1" url="$2" data="${3:-}"
  local out
  if [ -n "$data" ]; then
    out="$(curl -s -w '\n%{http_code}' -X "$method" "$url" \
      -H 'Content-Type: application/json' -d "$data")"
  else
    out="$(curl -s -w '\n%{http_code}' -X "$method" "$url")"
  fi
  STATUS="$(printf '%s' "$out" | tail -n 1)"
  BODY="$(printf '%s' "$out" | sed '$d')"
}

ok()   { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; echo "        status=$STATUS body=$BODY"; exit 1; }

expect_status() {
  if [ "$STATUS" = "$2" ]; then ok "$1"; else fail "$1 (cần $2, nhận $STATUS)"; fi
}
expect_2xx() {
  case "$STATUS" in 2*) ok "$1" ;; *) fail "$1 (cần mã 2xx, nhận $STATUS)" ;; esac
}
expect_error() {
  if [ "$STATUS" -ge 400 ]; then ok "$1"; else fail "$1 (cần mã lỗi >= 400, nhận $STATUS)"; fi
}
expect_json() {
  if echo "$BODY" | jq -e "$2" > /dev/null 2>&1; then ok "$1"; else fail "$1 (JSON không khớp: $2)"; fi
}

echo "== CRUD test: $API (pid=$PID) =="

echo "[1] Create"
request POST "$API" "{\"pid\":$PID,\"pname\":\"Laptop\",\"price\":15000000,\"quantity\":10}"
expect_2xx "POST tạo sản phẩm"
expect_json "Dữ liệu trả về đủ 4 trường" \
  ".pid == $PID and .pname == \"Laptop\" and .price == 15000 and .quantity == 10"

echo "[2] Create lỗi"
request POST "$API" "{\"pid\":$PID,\"pname\":\"Trung\",\"price\":1,\"quantity\":1}"
expect_error "Từ chối pid trùng"
request POST "$API" '{"pid":"abc","pname":"Sai kieu","price":1,"quantity":1}'
expect_error "Từ chối pid sai kiểu"

echo "[3] Read all"
request GET "$API"
expect_status "GET danh sách" 200
expect_json "Danh sách có sản phẩm vừa tạo" "any(.[]; .pid == $PID)"

echo "[4] Read one"
request GET "$API/$PID"
expect_status "GET một sản phẩm" 200
expect_json "Đúng sản phẩm" ".pid == $PID and .pname == \"Laptop\""

echo "[5] Update"
request PUT "$API/$PID" '{"price":14000000}'
expect_2xx "PUT cập nhật giá"
request GET "$API/$PID"
expect_json "Giá đã đổi, các trường khác giữ nguyên" \
  ".price == 14000000 and .quantity == 10 and .pname == \"Laptop\""

echo "[6] Delete"
request DELETE "$API/$PID"
expect_2xx "DELETE xóa sản phẩm"
request GET "$API/$PID"
expect_status "GET sau khi xóa trả 404" 404
request DELETE "$API/$PID"
expect_status "Xóa lần hai trả 404" 404

echo "[7] Sản phẩm không tồn tại"
request GET "$API/0"
expect_status "GET pid không tồn tại trả 404" 404

echo "== TẤT CẢ TEST ĐẠT =="