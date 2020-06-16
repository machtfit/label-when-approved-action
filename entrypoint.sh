#!/bin/bash
set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "Set the GITHUB_REPOSITORY env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
  echo "Set the GITHUB_EVENT_PATH env variable."
  exit 1
fi

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH" | tr '[:upper:]' '[:lower:]')
state=$(jq --raw-output .review.state "$GITHUB_EVENT_PATH" | tr '[:upper:]' '[:lower:]')
number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
reviewer=$(jq --raw-output .sender.login "$GITHUB_EVENT_PATH")


get_label() {
  declare -A first_names=(
    [or]="Oliver 👍"
    [fkoester]="Fabian 👍"
    [azd325]="Tim :+1:"
    [andreaseichelberg]="Andreas 👍"
    [klausbreuer]="Klaus 👍"
    [mbertheau]="Markus 👍"
  )

  user=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  label="${first_names[$user]}"
  echo "$label"
}

urlencode() {
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:i:1}"
    case $c in
      [a-zA-Z0-9.~_-]) printf "$c" ;;
      *) printf "$c" | xxd -p -c1 | while read x;do printf "%%%s" "$x";done
    esac
  done
}

label_when_approved() {
  echo "Labeling pull request"

  label="$(get_label "$reviewer")"
  if [[ ! -z "label" ]]; then
    curl -sSL \
      -H "${AUTH_HEADER}" \
      -H "${API_HEADER}" \
      -X POST \
      -H "Content-Type: application/json" \
      -d "{\"labels\":[\"${label}\"]}" \
      "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels"
  fi
}

label_when_changes_requested() {
  label="$(get_label "$reviewer")"

  encoded_label=$(urlencode "$label")
  curl -sSL \
    -H "${AUTH_HEADER}" \
    -H "${API_HEADER}" \
    -X DELETE \
    "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/${encoded_label}"

  changes_requested_label="Has open questions"
  curl -sSL \
    -H "${AUTH_HEADER}" \
    -H "${API_HEADER}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "{\"labels\":[\"${changes_requested_label}\"]}" \
    "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels"
}

if [[ "$action" == "submitted" ]] && [[ "$state" == "approved" ]]; then
  label_when_approved
elif [[ "$action" == "submitted" ]] && [[ "$state" == "changes_requested" ]]; then
  label_when_changes_requested
else
  echo "Ignoring event ${action}/${state}"
fi
