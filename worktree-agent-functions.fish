# Git Worktree Agent Helper Functions for Fish Shell
# Add these to your ~/.config/fish/config.fish

# Main function: Create worktree and launch agent
function willie
    set -l task_id ""
    set -l base_branch ""

    # Parse arguments
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case --from
                set i (math $i + 1)
                if test $i -le (count $argv)
                    set base_branch $argv[$i]
                else
                    echo "Error: --from requires a branch name"
                    return 1
                end
            case '*'
                if test -z "$task_id"
                    set task_id $argv[$i]
                else
                    echo "Error: Unknown argument '$argv[$i]'"
                    return 1
                end
        end
        set i (math $i + 1)
    end

    # Validate task ID
    if test -z "$task_id"
        echo "Usage: willie <task-id> [--from <base-branch>]"
        echo ""
        echo "Examples:"
        echo "  willie PCT-522"
        echo "  willie hotfix-123 --from main"
        return 1
    end

    # Check if we're in a git repo
    if not git rev-parse --git-dir > /dev/null 2>&1
        echo "Error: Not in a git repository"
        return 1
    end

    # Get repo root
    set -l repo_root (git rev-parse --show-toplevel)
    set -l worktree_dir "$repo_root/.worktrees/$task_id"

    # Check if worktree already exists
    if test -d "$worktree_dir"
        echo "Error: Worktree already exists at $worktree_dir"
        echo "Remove it first with: willie-clean $task_id"
        return 1
    end

    # Determine base branch
    if test -z "$base_branch"
        set base_branch (git branch --show-current)
        if test -z "$base_branch"
            set base_branch "main"
        end
    end

    # Create branch name
    set -l branch_name "$task_id"

    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$branch_name"
        echo "Error: Branch '$branch_name' already exists"
        echo "Use a different task ID or delete the existing branch first"
        return 1
    end

    echo "Creating worktree..."
    echo "  Task ID: $task_id"
    echo "  Branch: $branch_name (from $base_branch)"
    echo "  Location: $worktree_dir"
    echo ""

    # Create worktree with new branch
    if not git worktree add -b "$branch_name" "$worktree_dir" "$base_branch"
        echo "Error: Failed to create worktree"
        return 1
    end

    echo ""
    echo "Worktree created successfully!"
    echo "Launching Claude Code..."
    echo ""

    # Save current directory
    set -l orig_dir (pwd)

    # Change to worktree directory and launch Claude
    cd "$worktree_dir"; or return 1
    claude

    # After Claude exits, return to original directory
    cd "$orig_dir"
end

# List all worktrees
function willie-list
    echo "Git worktrees:"
    git worktree list
end

# Cleanup/remove worktree
function willie-clean
    set -l task_id "$argv[1]"

    if test -z "$task_id"
        echo "Current worktrees:"
        echo ""
        git worktree list
        echo ""
        echo "Usage: willie-clean <task-id>"
        echo "   or: willie-clean --all  (remove all worktrees except main)"
        return 0
    end

    # Get repo root
    set -l repo_root (git rev-parse --show-toplevel)

    if test "$task_id" = "--all"
        echo "Cleaning all worktrees in .worktrees/..."
        if test -d "$repo_root/.worktrees"
            for worktree_dir in $repo_root/.worktrees/*
                if test -d "$worktree_dir"
                    set -l wt_name (basename "$worktree_dir")
                    echo "Removing worktree: $wt_name"
                    git worktree remove "$worktree_dir" --force
                end
            end
            echo "All worktrees cleaned!"
        else
            echo "No .worktrees directory found"
        end
        return 0
    end

    set -l worktree_dir "$repo_root/.worktrees/$task_id"

    if not test -d "$worktree_dir"
        echo "Error: Worktree not found at $worktree_dir"
        echo ""
        echo "Available worktrees:"
        git worktree list
        return 1
    end

    echo "Removing worktree: $task_id"
    echo "Location: $worktree_dir"

    # Remove the worktree
    if git worktree remove "$worktree_dir" --force
        echo "Worktree removed successfully!"

        # Ask about deleting the branch
        echo ""
        read -P "Delete branch '$task_id'? (y/N) " -l response
        if test "$response" = "y" -o "$response" = "Y"
            git branch -D "$task_id"
            echo "Branch deleted!"
        end
    else
        echo "Error: Failed to remove worktree"
        return 1
    end
end

# Show help
function willie-help
    echo "Groundskeeper Willie - Git Worktree Helper for Claude Code

COMMANDS:
  willie <task-id> [options]
      Create a new worktree and launch Claude Code

      Options:
        --from <br>  Create branch from specified base branch

      Examples:
        willie PCT-522
        willie hotfix --from main

  willie-list
      List all active worktrees

  willie-clean <task-id>
      Remove a worktree and optionally its branch

      Use --all to remove all worktrees

      Examples:
        willie-clean PCT-522
        willie-clean --all

  willie-help
      Show this help message

WORKFLOW:
  1. Run: willie PCT-522
  2. Work in Claude Code session (in .worktrees/PCT-522/)
  3. Exit Claude when done
  4. Clean up: willie-clean PCT-522

NOTES:
  - Worktrees are stored in .worktrees/ (add to .gitignore)
  - Each worktree gets its own branch named after the task ID
  - Multiple Claude sessions can work in different worktrees simultaneously
  - Branches are NOT auto-deleted (manual cleanup)"
end
