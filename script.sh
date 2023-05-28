#!/bin/bash

# Set your iCloud directory path
ICLOUD_DIR=""

# Set your Notion integration token
NOTION_TOKEN=""

# Set the database ID or page ID where you want to post the transcriptions
DATABASE_ID=""

# Function to process new files
process_new_files() {
  for file in "$ICLOUD_DIR"/*.m4a; do
    # Check if the file has already been processed
    if [ ! -f "$file.processed" ]; then
      # Transcribe audio using Whisper AI
      transcription=$(whisper "$file" --language English)

      # Remove text in the format [00:00.000 --> 00:08.200] from the transcription
      cleaned_transcription=$(echo "$transcription" | sed -E 's/\[[0-9:.]+[[:space:]]?-->[[:space:]]?[0-9:.]+\]//g')

      # Extract the first four words from the cleaned transcription as the title
      title=$(echo "$cleaned_transcription" | awk '{for(i=1;i<=4;i++){printf "%s ", $i}}')
      title="$title..."

      # Remove leading/trailing whitespace and escape special characters in the content
      content=$(echo "$cleaned_transcription" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/"/\\"/g')

      notion_payload=$(jq -n \
        --arg database_id "$DATABASE_ID" \
        --arg title "$title" \
        --arg content "$content" \
        '{
            "parent": {
                "database_id": $database_id
            },
            "icon": {
                "emoji": "🎙️"
            },
            "properties": {
                "title": {
                    "title": [
                        {
                            "text": {
                                "content": $title
                            }
                        }
                    ]
                }
            },
            "children": [
                {
                  "object": "block",
                  "type": "paragraph",
                  "paragraph": {
                    "rich_text": [{
                      "type": "text",
                      "text": {
                        "content": $content
                      }
                    }]
                  }
                }
          ]
        }')

      # Post transcription to Notion
      notion_data=$(
        curl -sLX POST "https://api.notion.com/v1/pages" \
          -H "Authorization: Bearer $NOTION_TOKEN" \
          -H "Content-Type: application/json" \
          -H "Notion-Version: 2022-06-28" \
          -d "$notion_payload"
      )

      # Extract the new page ID from the API response
      page_id=$(echo "$notion_data" | jq -r '.id')

      echo "Transcription posted to Notion with page ID: $page_id"

      # Mark the file as processed
      touch "$file.processed"
    fi
  done
}

# Continuously monitor the directory for new files
while true; do
  process_new_files
  sleep 120 # Adjust the delay time (in seconds) as per your requirements
done
