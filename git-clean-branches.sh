#!/bin/bash

# Default values
TARGET_BRANCH="main"
FILTER_AUTHOR=""
FILTER_MERGED=""       
FILTER_UNMERGED_COMMITS="" 
INTERACTIVE_MODE=false

usage() {
    echo "Usage: \$0 [options]"
    echo "Options:"
    echo "  -b <branch>   Target branch to check merge status against (Default: main)"
    echo "  -c <creator>  Filter by creator (latest commit author)"
    echo "  -m <yes|no>   Filter if merged into target branch"
    echo "  -u <yes|no>   Filter if it has commits not merged into target branch"
    echo "  -i            Interactive mode"
    exit 1
}

# Parse flags safely
while getopts "b:c:m:u:ih" opt; do
    case "${opt}" in
        b) TARGET_BRANCH="${OPTARG}" ;;
        c) FILTER_AUTHOR="${OPTARG}" ;;
        m) FILTER_MERGED="${OPTARG}" ;;
        u) FILTER_UNMERGED_COMMITS="${OPTARG}" ;;
        i) INTERACTIVE_MODE=true ;;
        h|*) usage ;;
    esac
done

# Fetch latest remote updates safely
echo "Fetching latest updates from remote..."
git fetch --all --prune > /dev/null 2>&1

# Header format
printf "%-20s | %-40s | %-15s | %-22s | %-20s\n" "Last commit author" "Branch Name" "Merged to $TARGET_BRANCH" "Has Unmerged Commits" "Last Updated"
echo "------------------------------------------------------------------------------------------------------------------------"

# Temporary storage for interactive mode
declare -A MATCHED_BRANCHES
declare -A BRANCH_LOCAL_MAPPING

# Get all remote branches strictly using native git formatting
REMOTE_BRANCHES=$(git branch -r --format='%(refname:short)')

for ref in $REMOTE_BRANCHES; do
    # Skip HEAD pointers explicitly
    if [[ "$ref" == *"->"* ]]; then continue; fi

    # Clean remote branch name (origin/feature -> feature)
    REMOTE_NAME=$(echo "$ref" | cut -d'/' -f1)
    BRANCH_NAME=$(echo "$ref" | cut -d'/' -f2-)
    
    # 1. Last commit author (Author of the last commit)
    AUTHOR=$(git log -1 --format='%an' "$ref" 2>/dev/null)
    
    # 2. Last Updated Date
    LAST_UPDATED=$(git log -1 --format='%cr' "$ref" 2>/dev/null)
    
    # 3. Merged status
    if git merge-base --is-ancestor "$ref" "$TARGET_BRANCH" 2>/dev/null; then
        IS_MERGED="Yes"
    else
        IS_MERGED="No"
    fi
    
    # 4. Has commits not merged
    UNMERGED_COUNT=$(git rev-list --count "$TARGET_BRANCH..$ref" 2>/dev/null)
    if [ -n "$UNMERGED_COUNT" ] && [ "$UNMERGED_COUNT" -gt 0 ]; then
        HAS_UNMERGED="Yes ($UNMERGED_COUNT commits)"
    else
        HAS_UNMERGED="No"
    fi

    # ==================== STRICT FILTERING LAYER ====================
    # Last commit author filter validation (Case-Insensitive)
    if [ -n "$FILTER_AUTHOR" ]; then
        LOCAL_AUTHOR=$(echo "$AUTHOR" | tr '[:upper:]' '[:lower:]')
        LOCAL_FILTER=$(echo "$FILTER_AUTHOR" | tr '[:upper:]' '[:lower:]')
        if [[ ! "$LOCAL_AUTHOR" =~ "$LOCAL_FILTER" ]]; then 
            continue
        fi
    fi

    # Merged filter validation
    if [ -n "$FILTER_MERGED" ] && [ "${IS_MERGED,,}" != "${FILTER_MERGED,,}" ]; then 
        continue 
    fi

    # Unmerged commits filter validation
    if [ -n "$FILTER_UNMERGED_COMMITS" ]; then
        if [ "$FILTER_UNMERGED_COMMITS" == "yes" ] && [[ "$HAS_UNMERGED" == "No" ]]; then continue; fi
        if [ "$FILTER_UNMERGED_COMMITS" == "no" ] && [[ "$HAS_UNMERGED" == Yes* ]]; then continue; fi
    fi
    # ================================================================

    # Print Table Row ONLY if all filters pass
    printf "%-20.20s | %-40.40s | %-15s | %-22s | %-20s\n" "$AUTHOR" "$BRANCH_NAME" "$IS_MERGED" "$HAS_UNMERGED" "$LAST_UPDATED"

    # Save data for interactive step
    if [ "$INTERACTIVE_MODE" = true ]; then
        MATCHED_BRANCHES["$BRANCH_NAME"]="$AUTHOR | $BRANCH_NAME | $IS_MERGED | $HAS_UNMERGED | $LAST_UPDATED"
        BRANCH_LOCAL_MAPPING["$BRANCH_NAME"]="$REMOTE_NAME"
    fi
done

# Interactive Deletion Phase
if [ "$INTERACTIVE_MODE" = true ] && [ ${#MATCHED_BRANCHES[@]} -gt 0 ]; then
    echo -e "\n=== Entering Interactive Deletion Mode ===\n"
    for b_name in "${!MATCHED_BRANCHES[@]}"; do
        echo "------------------------------------------------------------------------------------------------------------------------"
        echo -e "Current Branch Details:\n${MATCHED_BRANCHES[$b_name]}"
        echo "------------------------------------------------------------------------------------------------------------------------"
        while true; do
            read -p "Do you want to delete this branch? (y: Remote only, Y: Remote & Local, n: Skip): " choice
            case "$choice" in
                y)
                    echo "Deleting remote branch: ${BRANCH_LOCAL_MAPPING[$b_name]}/$b_name..."
                    git push "${BRANCH_LOCAL_MAPPING[$b_name]}" --delete "$b_name"
                    break ;;
                Y)
                    echo "Deleting remote branch: ${BRANCH_LOCAL_MAPPING[$b_name]}/$b_name..."
                    git push "${BRANCH_LOCAL_MAPPING[$b_name]}" --delete "$b_name"
                    echo "Deleting local branch: $b_name..."
                    git branch -d "$b_name" 2>/dev/null || git branch -D "$b_name"
                    break ;;
                n)
                    echo "Skipping branch."
                    break ;;
                *)
                    echo "Invalid option. Please enter y, Y, or n." ;;
            esac
        done
    done
fi
