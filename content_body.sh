#!/bin/bash

# Read the text from standard input
text=$(cat)

# Split the text using the timestamp format
IFS='[' read -d '' -r -a segments <<<"$text"

# Remove the empty first element
segments=("${segments[@]:1}")

# Initialize the JSON structure with the required objects
json='{
  "parent": {
    "database_id": "'"${1}"'"
  },
  "icon": {
    "emoji": "🔴"
  },
  "properties": {
    "title": {
      "title": [
        {
          "text": {
            "content": "'"${2}"'"
          }
        }
      ]
    },
    "date_recorded": {
      "date": {
        "start": "'"${3}"'"
      }
    },
    "duration": {
      "type": "number",
      "number": '"${5}"'
    }
  },
  "children": [
    {
      "object": "block",
      "type": "heading_2",
      "heading_2": {
        "rich_text": [
          {
            "type": "text",
            "text": {
              "content": "Summary"
            }
          }
        ]
      }
    },
    {
      "object": "block",
      "type": "paragraph",
      "paragraph": {
        "rich_text": [
          {
            "type": "text",
            "text": {
              "content": "'"${4}"'"
            }
          }
        ]
      }
    },
    {
      "object": "block",
      "type": "heading_2",
      "heading_2": {
        "rich_text": [
          {
            "type": "text",
            "text": {
              "content": "Full Transcription"
            }
          }
        ]
      }
    }
  ]
}'

# Process each segment
for segment in "${segments[@]}"; do
  # Extract the content between the timestamps
  content=$(echo "$segment" | awk -F '] ' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  # Add the content to the JSON structure
  json=$(echo "$json" | jq --arg content "$content" '.children += [{"object": "block", "type": "paragraph", "paragraph": {"rich_text": [{"type": "text", "text": {"content": $content}}]}}]')
done

# Print the final JSON structure
echo "$json"
