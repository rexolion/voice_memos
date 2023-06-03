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
      # Get the creation date of the file
      creation_date=$(date -r "$file" "+%Y-%m-%dT%H:%M:%S%z")

      # Get the duration of the audio file using ffprobe
      duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")

      # Transcribe audio using Whisper AI
      transcription=$(whisper "$file" --language English --output_format txt --output_dir /tmp)

      # Remove text in the format [00:00.000 --> 00:08.200] from the transcription
      cleaned_transcription=$(echo "$transcription" | sed -E 's/\[[0-9:.]+[[:space:]]?-->[[:space:]]?[0-9:.]+\]//g')

      # Extract the file name without extension as the title
      filename=$(basename "$file")
      title="${filename%.*}"

      # Remove leading/trailing whitespace and escape special characters in the content
      content=$(echo "$cleaned_transcription" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/"/\\"/g')

      # Use GPT4ALL to summorize the transcription
      summorizedContent=$(python summorize.py "$content")

      # Remove crap logs before actual summary
      summorizedContent=$(echo $summorizedContent | sed 's/.*#//')

      # Remove the text before the newline (including the newline itself)
      escaped_transcription=$(printf "%q" "$transcription" | tr -d "'")

      # Get the body of Notion Api request
      content_body=$(echo "$escaped_transcription" | ./content_body.sh "$DATABASE_ID" "$title" "$creation_date" "$summorizedContent" "$duration" | sed 's@\\@@g')

      # Validate and format with jq
      body=$(echo "$content_body" | jq)

      # Post transcription to Notion
      notion_data=$(
        curl -sLX POST "https://api.notion.com/v1/pages" \
          -H "Authorization: Bearer $NOTION_TOKEN" \
          -H "Content-Type: application/json" \
          -H "Notion-Version: 2022-06-28" \
          -d "$body"
      )

      # Check if the request was successful
      if [ "$(echo "$notion_data" | jq -r '.object')" == "error" ]; then
        echo "Failed to post transcription of file '$file' to Notion: $(echo "$notion_data" | jq -r '.message')"
      else
        # Extract the new page ID from the API response
        page_id=$(echo "$notion_data" | jq -r '.id')
        echo "Transcription of file '$file' posted to Notion with page ID: $page_id"

        # Mark the file as processed
        touch "$file.processed"
      fi
    fi
  done
}

# Continuously monitor the directory for new files
while true; do
  process_new_files
  sleep 120 # Adjust the delay time (in seconds) as per your requirements
done
