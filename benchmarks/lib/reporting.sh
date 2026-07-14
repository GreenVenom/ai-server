#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Benchmark Framework
#
# Script: reporting.sh
#
# Purpose:
# Terminal and Markdown reporting.
#
# Responsibilities:
#   - Console output
#   - Markdown summaries
#   - Benchmark tables
#
# Version: 1.0.0
#
############################################################

[[ -n "${BENCHMARK_REPORTING_LOADED:-}" ]] && return
BENCHMARK_REPORTING_LOADED=1

############################################################
# Console
############################################################

report_banner() {

    echo
    divider
    center_text "Benchmark Framework"
    divider
    echo

}

############################################################

report_job() {

cat <<EOF

Provider      : ${BENCHMARK_PROVIDER}
Profile       : ${BENCHMARK_PROFILE}
Model          : ${BENCHMARK_MODEL}
Workload       : ${BENCHMARK_WORKLOAD}
Duration (ms)  : ${BENCHMARK_DURATION_MS}
Tokens/sec     : ${BENCHMARK_TOKENS_PER_SECOND}

EOF

}

############################################################

report_table_header() {

printf "%-20s %-18s %12s %12s\n" \
"Model" \
"Workload" \
"Time(ms)" \
"Tok/sec"

divider

}

############################################################

report_table_row() {

printf "%-20s %-18s %12s %12s\n" \
"${BENCHMARK_MODEL}" \
"${BENCHMARK_WORKLOAD}" \
"${BENCHMARK_DURATION_MS}" \
"${BENCHMARK_TOKENS_PER_SECOND}"

}

############################################################

report_summary() {

echo

divider

echo "Summary"

divider

echo

echo "Provider       : ${BENCHMARK_PROVIDER}"
echo "Profile        : ${BENCHMARK_PROFILE}"
echo "Model          : ${BENCHMARK_MODEL}"
echo "Workload       : ${BENCHMARK_WORKLOAD}"
echo "Duration (ms)  : ${BENCHMARK_DURATION_MS}"
echo "Tokens/sec     : ${BENCHMARK_TOKENS_PER_SECOND}"
echo "Memory (MB)    : ${BENCHMARK_MEMORY_MB}"
echo "CPU (%)        : ${BENCHMARK_CPU_PERCENT}"

echo

}

############################################################
# Markdown
############################################################

markdown_summary() {

cat <<EOF
# Benchmark Summary

| Metric | Value |
|--------|------:|
| Provider | ${BENCHMARK_PROVIDER} |
| Profile | ${BENCHMARK_PROFILE} |
| Model | ${BENCHMARK_MODEL} |
| Workload | ${BENCHMARK_WORKLOAD} |
| Duration (ms) | ${BENCHMARK_DURATION_MS} |
| Tokens/sec | ${BENCHMARK_TOKENS_PER_SECOND} |
| Memory (MB) | ${BENCHMARK_MEMORY_MB} |
| CPU (%) | ${BENCHMARK_CPU_PERCENT} |

EOF

}

############################################################

save_markdown_summary() {

    local file="$1"

    markdown_summary > "$file"

}