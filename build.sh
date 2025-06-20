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

# Debug version - let's see what's actually happening
echo "=== DEBUGGING SORT PROCESS ==="

echo "1. Original data (first few items):"
echo "$FILTERED_MATRIX" | jq -r '.include[0:5][].name'

echo -e "\n2. Testing regex capture on each name:"
echo "$FILTERED_MATRIX" | jq -r '.include[].name | . as $name | try (capture("^(?<product>\\S+)\\s+(?<major>\\d+)\\.(?<minor>\\d+)") | "✓ \($name) -> major:\(.major) minor:\(.minor)") catch "✗ \($name) -> NO MATCH"'

echo -e "\n3. Testing version conversion:"
echo "$FILTERED_MATRIX" | jq -c '.include[].name | . as $name | try (capture("^(?<product>\\S+)\\s+(?<major>\\d+)\\.(?<minor>\\d+)") | {name: $name, major: (.major | tonumber), minor: (.minor | tonumber)}) catch {name: $name, error: "no match"}'

echo -e "\n4. Testing full sort key generation:"
echo "$FILTERED_MATRIX" | jq -c '.include[] | {
  name: .name,
  sort_key: (if (.name | test("^\\S+\\s+\\d+\\.\\d+")) then
    (.name | capture("^(?<product>\\S+)\\s+(?<major>\\d+)\\.(?<minor>\\d+)") |
     [(.major | tonumber), (.minor | tonumber), .name])
  else
    [999, 999, .name]
  end)
}'

echo -e "\n5. Applying the sort and showing result:"
echo "$FILTERED_MATRIX" | jq -c '
.include |= sort_by(
  if (.name | test("^\\S+\\s+\\d+\\.\\d+")) then
    (.name | capture("^(?<product>\\S+)\\s+(?<major>\\d+)\\.(?<minor>\\d+)") |
     [(.major | tonumber), (.minor | tonumber), .name])
  else
    [999, 999, .name]
  end
) | .include[].name'

echo -e "\n6. Final result assigned to output:"


echo "final-matrix=$(echo "$FILTERED_MATRIX" | jq -c '.include |= sort_by(
  if (.name | test("^\\\\S+\\\\s+\\\\d+\\\\.\\\\d+")) then
    (.name | capture("^(?<product>\\\\S+)\\\\s+(?<major>\\\\d+)\\\\.(?<minor>\\\\d+)") |
     [(.major | tonumber), (.minor | tonumber), .name])
  else
    [999, 999, .name]
  end
)')" >> "$GITHUB_OUTPUT"