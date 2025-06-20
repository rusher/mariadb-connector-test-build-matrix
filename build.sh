#!/bin/bash

# Load the base test matrix
BASE_MATRIX=$(cat "$GITHUB_ACTION_PATH/test-matrix.json")

# Check if ADDITIONAL_MATRIX is provided and not empty
if [ -n "${ADDITIONAL_MATRIX}" ]; then
    # Combine the matrices by merging the include arrays
    # BASE_MATRIX has format: {"include": [...]}
    # ADDITIONAL_MATRIX should be an array: [...]
    FINAL_MATRIX=$(echo "$BASE_MATRIX" "$ADDITIONAL_MATRIX" | jq -s '{include: (.[0].include + .[1])}')
else
    # Use the base matrix as-is
    FINAL_MATRIX="$BASE_MATRIX"
fi

# Filter the matrix based on GitHub event type
if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
    # Filter out enterprise db-type entries for pull requests
    FILTERED_MATRIX=$(echo "$FINAL_MATRIX" | jq '{
        include: [.include[] | select(.["db-type"] != "enterprise")]
    }')
else
    # Use the full matrix for other events
    FILTERED_MATRIX="$FINAL_MATRIX"
fi

# Test 1: Check if the regex capture is working
echo "$FILTERED_MATRIX" | jq -r '.include[].name | select(test("MariaDB")) | capture("^(?<product>\\S+)\\s+(?<version>\\d+\\.\\d+)") | "\(.product) \(.version)"'

# Test 2: Check if version splitting is working
echo "$FILTERED_MATRIX" | jq -r '.include[].name | select(test("MariaDB")) | capture("^(?<product>\\S+)\\s+(?<version>\\d+\\.\\d+)") | .version | split(".") | join(",")'

# Test 3: Check if tonumber is working
echo "$FILTERED_MATRIX" | jq -c '.include[].name | select(test("MariaDB")) | capture("^(?<product>\\S+)\\s+(?<version>\\d+\\.\\d+)") | .version | split(".") | map(tonumber)'

# Test 4: Check the full sort key
echo "$FILTERED_MATRIX" | jq -c '.include[] | select(.name | test("MariaDB")) | [(.name | capture("^(?<product>\\S+)\\s+(?<version>\\d+\\.\\d+)") | .version | split(".") | map(tonumber)), .name]'

echo "final-matrix=$(echo "$FILTERED_MATRIX" | jq -c '.include |= sort_by([
  (.name | capture("^(?<product>\\\\S+)\\\\s+(?<version>\\\\d+\\\\.\\\\d+)"; "g") // {} | .product // .name),
  (.name | capture("^(?<product>\\\\S+)\\\\s+(?<major>\\\\d+)\\\\.(?<minor>\\\\d+)"; "g") // {} | (.major // "0") | tonumber),
  (.name | capture("^(?<product>\\\\S+)\\\\s+(?<major>\\\\d+)\\\\.(?<minor>\\\\d+)"; "g") // {} | (.minor // "0") | tonumber),
  .name
])')" >> "$GITHUB_OUTPUT"
