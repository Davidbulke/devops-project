#!/bin/bash

# Exit immediately if any command fails
set -e

# --- CUSTOMIZE THIS LIST ---
# List of branch names from upstream (hkhcoder) to recreate in origin (davidbulke)
# Use the exact names from hkhcoder's repository.
# IMPORTANT: Make sure to EXCLUDE 'master' from this list!
BRANCHES_TO_RECREATE=(
    "local"
    "main"
    "ci-jenkins"
    "jenkins-ci"
    "atom"
    "patch-1"
    "containers"
    "terraform-project"
    "prereqs"
    "awsliftandshift"
    "docker"
    "variable"
    "kubeapp"
    "jdk11"
    "buzzfractor"
    "seleniumAutoScripts"
    "ci-ans"
    "ans_11"
    "terraform-eks" # Added from your screenshot
    # Add any other branches from hkhcoder's repo you need
)
# --- END CUSTOMIZATION ---

echo "Starting branch recreation process..."
echo "Will process ${#BRANCHES_TO_RECREATE[@]} branches."
echo "-------------------------------------"

# Ensure remotes exist and are up-to-date
echo "Fetching updates from origin and upstream..."
git fetch origin
git fetch upstream
echo "-------------------------------------"

# Remember the current branch to return later
# current_branch=$(git symbolic-ref --short HEAD) # Not strictly needed as we checkout master each time

for branch_name in "${BRANCHES_TO_RECREATE[@]}"; do
    echo "Processing branch: $branch_name ..."
    temp_name="temp-$branch_name"

    # 1. Clean Up Locally & Go to Master
    echo "  Cleaning up local branches and switching to master..."
    # echo "  Cleaning potentially untracked target/ directory..." # REMOVE THIS
    # rm -rf target/ # REMOVE THIS
    git checkout master > /dev/null # Check out master
    # Delete potentially existing local branches from previous runs, ignore errors if they don't exist
    git branch -D "$branch_name" > /dev/null 2>&1 || true
    git branch -D "$temp_name" > /dev/null 2>&1 || true

    # 2. Create Orphan Branch
    echo "  Creating orphan branch $temp_name..."
    git checkout --orphan "$temp_name" > /dev/null

    # 3. Empty Workspace
    echo "  Emptying workspace..."
    git rm -rf --cached . > /dev/null
    git clean -fdx > /dev/null

    # 4. Get Upstream Code
    echo "  Checking out code from upstream/$branch_name..."
    # Use git ls-remote to check if upstream branch exists before checkout
    if git ls-remote --exit-code --heads upstream "$branch_name" > /dev/null; then
        git checkout "upstream/$branch_name" -- .
    else
        echo "  WARNING: Branch '$branch_name' not found on upstream remote. Creating empty branch."
        # Optionally create an empty commit here if you want the branch to exist but be empty
        # git commit --allow-empty -m "Create empty branch $branch_name (upstream source not found)" > /dev/null
        # For now, we'll let the commit step handle it (it might create an empty commit anyway or just finish)
    fi

    # 5. Check Status and Commit (if changes exist)
    echo "  Staging changes..."
    git add .
    # Check if there are changes staged for commit
    # Use 'git diff --staged --quiet' which returns 0 if no changes, 1 if changes
    if ! git diff --staged --quiet; then
        echo "  Committing changes..."
        git commit -m "Import final code state for $branch_name from upstream" > /dev/null
    else
        echo "  No file changes detected between upstream/$branch_name and master; creating empty placeholder commit."
        # Create an empty commit to ensure the branch ref is created, even if content matches master
        git commit --allow-empty -m "Import final code state for $branch_name from upstream (no file changes detected vs master)" > /dev/null
    fi

    # 6. Push to origin
    echo "  Pushing $branch_name to origin..."
    git push --force origin "$temp_name:$branch_name"
    # OR use: git push -f origin "$temp_name:$branch_name"

    # 7. Cleanup Local Temp Branch
        echo "  Cleaning up temporary branch $temp_name..."
        echo "  Cleaning potentially untracked target/ directory before switching back to master..."
        rm -rf target/
        git checkout master > /dev/null # Switch back to master
        git branch -D "$temp_name" > /dev/null # Delete the temp branch

        echo "  Finished processing branch: $branch_name"
        echo "-------------------------------------"
    done

    echo "Branch recreation process complete."
