git_contrib() {

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "❌ Not inside a git repository"
        return 1
    }

    EXCLUDES=("node_modules" "vendor" "Pods" "dist" "build" ".git")

    PATHSPEC=()
    for d in "${EXCLUDES[@]}"; do
        PATHSPEC+=(":(exclude)$d")
    done

    git log \
        --no-merges \
        --pretty="AUTHOR:%an|%ae" \
        --numstat -- . "${PATHSPEC[@]}" |
    awk '
    BEGIN { author="" }

    /^AUTHOR:/ {
        author = substr($0,8)
        next
    }

    # only valid numeric insertion lines
    $1 ~ /^[0-9]+$/ {
        added = $1
        contrib[author] += added
        total += added
    }

    END {
        for (a in contrib) {
            pct = (contrib[a] / total) * 100
            printf "%s|%.2f\n", a, pct
        }
    }' |
    sort -t'|' -k2 -nr |
    awk -F'|' '
    BEGIN { others=0 }

    {
        if ($2 < 1.5) {
            others += $2
            next
        }

        bar_len = int($2/2)
        bar = ""
        for(i=0;i<bar_len;i++) bar = bar "█"

        printf "%-40s : %6.2f%%  %s\n", $1, $2, bar
    }

    END {
        if (others > 0) {
            bar_len = int(others/2)
            bar=""
            for(i=0;i<bar_len;i++) bar = bar "█"

            printf "%-40s : %6.2f%%  %s\n", "Others", others, bar
        }
    }'
}