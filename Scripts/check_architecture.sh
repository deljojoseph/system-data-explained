#!/bin/sh

set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_directory=$(CDPATH= cd -- "$script_directory/.." && pwd)
source_directory="$project_directory/Sources"
domain_directory="$source_directory/SDEDomain"
presentation_directory="$source_directory/SystemDataExplained/Presentation"

failure=0

check_absent() {
    pattern=$1
    directory=$2
    description=$3

    if rg -n "$pattern" "$directory"; then
        echo "Architecture check failed: $description"
        failure=1
    fi
}

check_absent '\.(removeItem|moveItem|replaceItem|trashItem)[[:space:]]*\(' "$source_directory" "production filesystem mutation API found"
check_absent '(^|[^A-Za-z])(Process|NSTask)[[:space:]]*\(' "$source_directory" "production shell execution found"
check_absent 'URLSession|URLRequest|NWConnection|import[[:space:]]+Network' "$source_directory" "production network capability found"
check_absent 'import[[:space:]]+(StoreKit|Telemetry|Analytics)' "$source_directory" "commerce, telemetry, or analytics framework found"
check_absent '^import[[:space:]]+(SwiftUI|AppKit|StoreKit)$' "$domain_directory" "domain imports a forbidden framework"
check_absent 'FileManager|NSFileManager' "$presentation_directory" "presentation accesses the filesystem directly"
check_absent 'func[[:space:]]+(delete|remove|move|rename|write|clean|repair)[A-Za-z0-9_]*[[:space:]]*\(' "$source_directory/SDEApplication" "application protocol exposes a mutation operation"
check_absent '\.font\(\.(caption|caption2|footnote)' "$presentation_directory" "essential presentation copy uses caption-sized type"
check_absent 'ruleID:[[:space:]]*"unknown"[[:space:]]*[,)]' "$source_directory/SDEEngine" "global unknown accumulator found"
check_absent '(?i)"[^"]*(scan|scanner|clean|cleanup|optimise|optimize)[^"]*"' "$presentation_directory" "commodity cleaner language found in presentation copy"
check_absent 'Navigation(Stack|Link)' "$presentation_directory" "page-stack navigation found in the single-cockpit presentation"
check_absent '—|\\u\{2014\}' "$source_directory" "em dash found in production copy"

if [ "$failure" -ne 0 ]; then
    exit 1
fi

echo "Architecture safety checks passed."
