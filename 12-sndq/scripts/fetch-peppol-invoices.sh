#!/usr/bin/env bash
#
# Fetch Peppol invoices from the SNDQ backend API.
#
# Usage:
#   ./fetch-peppol-invoices.sh                         # all received invoices
#   ./fetch-peppol-invoices.sh --status received       # filter by status
#   ./fetch-peppol-invoices.sh --limit 10              # limit results
#   ./fetch-peppol-invoices.sh --page 2 --limit 25     # pagination
#   ./fetch-peppol-invoices.sh --sort-by issueDate --sort-dir asc
#   ./fetch-peppol-invoices.sh --search "Besox"        # search by name/number
#   ./fetch-peppol-invoices.sh --raw                   # output raw JSON
#   ./fetch-peppol-invoices.sh --id <invoice-id>       # get single invoice detail
#
# Environment variables:
#   API_URL       - Backend URL (default: http://localhost:8000)
#   WORKSPACE_ID  - Workspace UUID (default: 64d95b9a-7d77-4dbb-b9f4-f98b14741b70)
#   AUTH_EMAIL    - Login email (default: admin@sndq.dev)
#   AUTH_PASSWORD  - Login password (default: Admin@123)
#   AUTH_TOKEN    - Pre-set token (skips login if provided)

set -euo pipefail

API_URL="${API_URL:-http://localhost:8000}"
WORKSPACE_ID="${WORKSPACE_ID:-64d95b9a-7d77-4dbb-b9f4-f98b14741b70}"
AUTH_EMAIL="${AUTH_EMAIL:-admin@sndq.dev}"
AUTH_PASSWORD="${AUTH_PASSWORD:-Admin@123}"

# Defaults
PAGE=1
LIMIT=25
STATUS=""
SORT_BY="createdAt"
SORT_DIR="desc"
SEARCH=""
RAW=false
INVOICE_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --page)       PAGE="$2"; shift 2 ;;
    --limit)      LIMIT="$2"; shift 2 ;;
    --status)     STATUS="$2"; shift 2 ;;
    --sort-by)    SORT_BY="$2"; shift 2 ;;
    --sort-dir)   SORT_DIR="$2"; shift 2 ;;
    --search)     SEARCH="$2"; shift 2 ;;
    --raw)        RAW=true; shift ;;
    --id)         INVOICE_ID="$2"; shift 2 ;;
    --help|-h)
      head -n 16 "$0" | tail -n +3 | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

get_token() {
  if [[ -n "${AUTH_TOKEN:-}" ]]; then
    echo "$AUTH_TOKEN"
    return
  fi
  curl -sf -X POST "${API_URL}/auth/login" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"${AUTH_EMAIL}\",\"password\":\"${AUTH_PASSWORD}\"}" \
    | jq -r '.accessToken'
}

TOKEN="$(get_token)"
if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "ERROR: Failed to authenticate" >&2
  exit 1
fi

# Single invoice detail
if [[ -n "$INVOICE_ID" ]]; then
  RESULT=$(curl -sf "${API_URL}/peppol/invoices/${INVOICE_ID}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/json")

  if $RAW; then
    echo "$RESULT"
  else
    echo "$RESULT" | jq '{
      id,
      invoiceNumber,
      type,
      status,
      source,
      issueDate,
      dueDate,
      supplier: .supplierParty.name,
      supplierVat: .supplierParty.vatNumber,
      customer: .customerParty.name,
      customerVat: .customerParty.vatNumber,
      taxExclusive: (.taxExclusiveAmount / 100),
      taxInclusive: (.taxInclusiveAmount / 100),
      payable: (.payableAmount / 100),
      currency,
      lineCount: (.lines | length),
      hasAttachments,
      note,
      createdAt
    }'
  fi
  exit 0
fi

# Build query string
# Available sort fields: createdAt, updatedAt, invoiceNumber, supplierPartyName,
#   customerPartyName, issueDate, dueDate, taxExclusiveAmount, taxInclusiveAmount,
#   payableAmount, status, source
# Available filter fields: type ($in: invoice, credit_note), status ($in: received,
#   converted, accepted, rejected), source ($in: manual, sndq), issueDate, dueDate,
#   typeCode, taxExclusiveAmount, taxInclusiveAmount, payableAmount, createdAt,
#   updatedAt, participantId, buildingId, buildingManagerUserId, supplierVatNumber
QUERY="workspaceId=${WORKSPACE_ID}&page=${PAGE}&limit=${LIMIT}"
QUERY+="&sort%5B${SORT_BY}%5D=${SORT_DIR}"

if [[ -n "$STATUS" ]]; then
  QUERY+="&filter%5Bstatus%5D%5B%24in%5D%5B0%5D=${STATUS}"
fi

if [[ -n "$SEARCH" ]]; then
  QUERY+="&search=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${SEARCH}'))")"
fi

RESULT=$(curl -sf "${API_URL}/peppol/invoices?${QUERY}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/json" \
  -H "x-lang: en")

if $RAW; then
  echo "$RESULT"
  exit 0
fi

TOTAL=$(echo "$RESULT" | jq '.total')
DOC_COUNT=$(echo "$RESULT" | jq '.docs | length')

echo "=== Peppol Invoices (page ${PAGE}, ${DOC_COUNT}/${TOTAL} total) ==="
echo ""

echo "$RESULT" | jq -r '.docs[] | [
  .invoiceNumber,
  .status,
  .type,
  .supplierParty.name,
  .customerParty.name,
  ((.payableAmount / 100 | tostring) + " " + .currency),
  .issueDate
] | @tsv' | column -t -s $'\t'

echo ""
echo "Tip: use --raw to get full JSON, --id <uuid> for detail, --help for all options"
