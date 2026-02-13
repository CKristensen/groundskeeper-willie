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
        case --next
            _willie_next $argv[2..-1]
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

# Launch next highest priority ticket from prd.json
function _willie_next
    set -l base_branch ""

    # Parse optional --from argument
    set -l i 1
    while test $i -le (count $argv)
        if test "$argv[$i]" = "--from"
            set i (math $i + 1)
            if test $i -le (count $argv)
                set base_branch $argv[$i]
            else
                echo "Error: --from requires a branch name"
                return 1
            end
        end
        set i (math $i + 1)
    end

    # Check if prd.json exists
    if not test -f "prd.json"
        echo "Error: prd.json not found in current directory"
        echo "Make sure you're in a project with a PRD file"
        return 1
    end

    # Check if jq is installed
    if not command -v jq > /dev/null 2>&1
        echo "Error: jq is required but not installed"
        echo "Install with:"
        echo "  - Ubuntu/Debian: sudo apt-get install jq"
        echo "  - macOS: brew install jq"
        echo "  - Fedora: sudo dnf install jq"
        return 1
    end

    # Get repo root to check for existing worktrees
    set -l repo_root (git rev-parse --show-toplevel)
    
    # Get list of existing worktree IDs
    set -l existing_worktrees ""
    if test -d "$repo_root/.worktrees"
        set existing_worktrees (ls -1 "$repo_root/.worktrees" 2>/dev/null | string join ',')
    end
    
    # Get highest priority incomplete ticket that's not already in a worktree
    set -l ticket_json (jq -c --arg existing "$existing_worktrees" '
        ($existing | split(",") | map(select(length > 0))) as $worktree_ids |
        .userStories
        | map(select(
            .passes == false and 
            (.id as $ticket_id | $worktree_ids | any(. == $ticket_id) | not)
          ))
        | sort_by(.priority)
        | .[0]
    ' prd.json)

    # Check if any ticket found
    if test "$ticket_json" = "null" -o -z "$ticket_json"
        echo "No incomplete tickets found in prd.json"
        echo "All user stories are marked as passing!"
        return 0
    end

    # Extract ticket details
    set -l task_id (echo "$ticket_json" | jq -r '.id')
    set -l title (echo "$ticket_json" | jq -r '.title')
    set -l description (echo "$ticket_json" | jq -r '.description')
    set -l criteria (echo "$ticket_json" | jq -r '.acceptanceCriteria | join("\n- ")')
    set -l priority (echo "$ticket_json" | jq -r '.priority')

    echo "========================================="
    echo "Next Ticket: $task_id (Priority $priority)"
    echo "========================================="
    echo "Title: $title"
    echo ""
    echo "Creating worktree and launching autonomous agent..."
    echo ""

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

    # Mark ticket as in_progress in prd.json
    jq --arg id "$task_id" '
        .userStories |= map(
            if .id == $id then
                . + {status: "in_progress"}
            else
                .
            end
        )
    ' prd.json > prd.json.tmp; and mv prd.json.tmp prd.json

    echo "Marked ticket $task_id as 'in_progress' in prd.json"
    echo ""

    # Create worktree with new branch
    if not git worktree add -b "$branch_name" "$worktree_dir" "$base_branch"
        echo "Error: Failed to create worktree"
        # Revert status change on failure
        jq --arg id "$task_id" '
            .userStories |= map(
                if .id == $id then
                    del(.status)
                else
                    .
                end
            )
        ' prd.json > prd.json.tmp; and mv prd.json.tmp prd.json
        return 1
    end

    # Create TICKET.md file in worktree with full ticket details
    echo "# Ticket: $task_id

**Priority:** $priority
**Title:** $title

## Description

$description

## Acceptance Criteria

- $criteria

## Instructions for Autonomous Agent

You are working on this ticket autonomously. Your goals:

1. **Read and understand** all acceptance criteria above
2. **Explore the codebase** to understand the existing implementation
3. **Implement** all required functionality to meet the acceptance criteria
4. **Test** your changes thoroughly (run tests, manual testing, etc.)
5. **Update prd.json** when complete:
   - Set \`\"passes\": true\` for this ticket ($task_id)
   - Add detailed notes about what was implemented
6. **Commit your changes** with a clear commit message

## Ralph Loop Guidance

Work iteratively:
- Break the task into smaller steps if needed
- Test as you go
- Don't over-engineer - implement exactly what's needed
- Follow existing code patterns in the project
- If you encounter blockers, document them in the notes field

When you've met all acceptance criteria and tested thoroughly, update prd.json and commit your work.

---
*This ticket was generated by Willie's --next command*" > "$worktree_dir/TICKET.md"

    echo ""
    echo "Worktree created successfully!"
    echo "Ticket details written to TICKET.md"
    echo "Launching Claude Code in autonomous mode..."
    echo ""

    # Save current directory
    set -l orig_dir (pwd)

    # Change to worktree directory and launch Claude with the ticket
    cd "$worktree_dir"; or return 1
    claude "Read TICKET.md and work autonomously on ticket $task_id: $title. Follow the Ralph Loop guidance. When complete, update prd.json to mark this ticket as passing and commit your changes."

    # After Claude exits, return to original directory
    cd "$orig_dir"
end

# Show help
function _willie_help
    echo "Groundskeeper Willie - Git Worktree Helper for Claude Code

USAGE:
  willie <task-id> [--from <branch>]    Create worktree and launch Claude
  willie --next [--from <branch>]       Auto-launch highest priority ticket from prd.json
  willie --status                        List all worktrees
  willie --clean <task-id>               Remove worktree
  willie --help                          Show this help

OPTIONS:
  --from <branch>    Create branch from specified base branch

EXAMPLES:
  willie PCT-522                Create worktree for task PCT-522
  willie hotfix --from main     Create worktree from main branch
  willie --next                 Launch next incomplete ticket from prd.json
  willie --status               List all active worktrees
  willie --clean PCT-522        Remove worktree for PCT-522
  willie --clean --all          Remove all worktrees

WORKFLOW:
  1. willie PCT-522             # Create worktree and launch Claude
  2. [Work in Claude session]   # Make changes in .worktrees/PCT-522/
  3. [Exit Claude]              # Return to main workspace
  4. willie --clean PCT-522     # Clean up when done

RALPH LOOP WORKFLOW (AUTONOMOUS):
  1. willie --next              # Auto-launch highest priority incomplete ticket
  2. [Claude works autonomously] # Agent reads TICKET.md and implements changes
  3. [Claude updates prd.json]  # Marks ticket as complete when done
  4. [Exit Claude]              # Return to main workspace

NOTES:
  - Worktrees are stored in .worktrees/ (add to .gitignore)
  - Each worktree gets its own branch named after the task ID
  - Multiple Claude sessions can work in different worktrees simultaneously
  - Branches are NOT auto-deleted (manual cleanup)
  - --next requires prd.json and jq to be installed"
end
