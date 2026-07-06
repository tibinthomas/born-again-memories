#!/bin/sh
# PreToolUse hook for Bash: if the command looks like a raw-file search
# and a graphify knowledge graph exists, point the agent at the graph
# report instead of grepping raw files.
CMD=$(python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',d).get('command',''))")

case "$CMD" in
  *grep*|*rg\ *|*ripgrep*|*find\ *|*fd\ *|*ack\ *|*ag\ *)
    if [ -f graphify-out/graph.json ]; then
      echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"graphify: Knowledge graph exists. Read graphify-out/GRAPH_REPORT.md for god nodes and community structure before searching raw files."}}'
    fi
    ;;
esac
