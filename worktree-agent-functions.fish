# Git Worktree Agent Helper Functions for Fish Shell
# Add these to your ~/.config/fish/config.fish

function willie
    # Handle flags
    set -l cmd "$argv[1]"

    switch "$cmd"
        case --help -h
            _willie_help
        case --status
            _willie_status
        case --clean
            _willie_clean $argv[2..-1]
        case ""
            _willie_help
            return 1
        case '--*'
            echo "Error: Unknown option '$cmd'"
            echo "Use 'willie --help' for usage information"
            return 1
        case '*'
            # Default: create worktree
            _willie_create $argv
    end
end

# Create worktree and launch agent
function _willie_create
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
        echo "Remove it first with: willie --clean $task_id"
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
function _willie_status
    echo "Git worktrees:"
    git worktree list
end

# Cleanup/remove worktree
function _willie_clean
    set -l task_id "$argv[1]"

    if test -z "$task_id"
        echo "Current worktrees:"
        echo ""
        git worktree list
        echo ""
        echo "Usage: willie --clean <task-id>"
        echo "   or: willie --clean --all  (remove all worktrees)"
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
function _willie_help
    echo "Groundskeeper Willie - Git Worktree Helper for Claude Code

USAGE:
  willie <task-id> [--from <branch>]    Create worktree and launch Claude
  willie --status                        List all worktrees
  willie --clean <task-id>               Remove worktree
  willie --help                          Show this help

OPTIONS:
  --from <branch>    Create branch from specified base branch

EXAMPLES:
  willie PCT-522                Create worktree for task PCT-522
  willie hotfix --from main     Create worktree from main branch
  willie --status               List all active worktrees
  willie --clean PCT-522        Remove worktree for PCT-522
  willie --clean --all          Remove all worktrees

WORKFLOW:
  1. willie PCT-522             # Create worktree and launch Claude
  2. [Work in Claude session]   # Make changes in .worktrees/PCT-522/
  3. [Exit Claude]              # Return to main workspace
  4. willie --clean PCT-522     # Clean up when done

NOTES:
  - Worktrees are stored in .worktrees/ (add to .gitignore)
  - Each worktree gets its own branch named after the task ID
  - Multiple Claude sessions can work in different worktrees simultaneously
  - Branches are NOT auto-deleted (manual cleanup)"
end
