#!/bin/bash
JSON_FILE="/home/user/archives.json" # Location to json containing archives directory and desired folder name
LOG_UNAVAILABLE="/home/user/extract-unavailable.log" # Location to log
LOG_ARCHIVE="/home/user/extract-7z.log" # Location to log
ARCHIVE_DIR="/home/user/archives-location" # Location to archives
DEST_DIR="/home/user/destination" # Location to destination
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
MAX_JOBS=12 # Number of threads 

#Time logging
START=$(date +%s)

# Create logs
echo "$timestamp" > $LOG_UNAVAILABLE 
echo "$timestamp" > $LOG_ARCHIVE 

# Read json file and pipe into parallel
jq -r \
  --arg ad "$ARCHIVE_DIR" \
  --arg dd "$DEST_DIR" \
  --arg la "$LOG_ARCHIVE" \
  --arg lu "$LOG_UNAVAILABLE" \
  '
  .[] |
  .archive as $a |
  .directory as $d |
  [$a, ($ad + "/" + $a), $d, ($dd + "/" + $d), $la, $lu] |
  @tsv
  ' "$JSON_FILE" | parallel --colsep '\t' -j"$MAX_JOBS" "
  archive_name="{1}"
  archive_path="{2}"
  dest_folder="{3}"
  output_dir="{4}"
  LOG_ARCHIVE="{5}"
  LOG_UNAVAILABLE="{6}"
  if [[ ! -f {2} ]]; then
    tee -a {6} <<< \"Archive not found: {2}. Skipping.\"
  else
    echo \"Extracting {1}\" >> {5}
    case {1} in
      *.rar|*.RAR)
        unrar -y e {2} {4} >/dev/null
        ;;
      *)
        7z x -y {2} -o{4} >/dev/null
        ;;
    esac 
  fi
"

# Calculate runtime
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "Script finished after $DIFF seconds" >> $LOG_ARCHIVE 
