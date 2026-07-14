#!/bin/bash

############################################################
#
# Personal AI Platform
#
# Benchmark Framework
#
# Script: statistics.sh
#
# Purpose:
# Statistical calculations for benchmark results.
#
# Responsibilities:
#   - Average
#   - Median
#   - Minimum
#   - Maximum
#   - Standard deviation
#   - Throughput calculations
#
# Version: 1.0.0
#
############################################################

[[ -n "${BENCHMARK_STATISTICS_LOADED:-}" ]] && return
BENCHMARK_STATISTICS_LOADED=1

############################################################
# Average
############################################################

statistics_average() {

    awk '
    {
        sum += $1
        count++
    }

    END {

        if (count == 0) {
            print 0
            exit
        }

        printf "%.3f", sum / count

    }'

}

############################################################
# Minimum
############################################################

statistics_min() {

    awk '

    NR == 1 {

        min = $1

    }

    {

        if ($1 < min)
            min = $1

    }

    END {

        printf "%.3f", min

    }'

}

############################################################
# Maximum
############################################################

statistics_max() {

    awk '

    NR == 1 {

        max = $1

    }

    {

        if ($1 > max)
            max = $1

    }

    END {

        printf "%.3f", max

    }'

}

############################################################
# Median
############################################################

statistics_median() {

    sort -n |

    awk '

    {

        a[NR] = $1

    }

    END {

        if (NR == 0) {

            print 0

            exit

        }

        if (NR % 2) {

            printf "%.3f", a[(NR+1)/2]

        }

        else {

            printf "%.3f",

            (a[NR/2] + a[(NR/2)+1]) / 2

        }

    }'

}

############################################################
# Standard Deviation
############################################################

statistics_stddev() {

    awk '

    {

        values[NR] = $1

        sum += $1

    }

    END {

        if (NR < 2) {

            print 0

            exit

        }

        mean = sum / NR

        for(i=1;i<=NR;i++) {

            variance += (values[i]-mean)^2

        }

        variance /= NR

        printf "%.3f", sqrt(variance)

    }'

}

############################################################
# Tokens Per Second
############################################################

statistics_tokens_per_second() {

    local tokens="$1"

    local seconds="$2"

    awk -v t="$tokens" -v s="$seconds" '

    BEGIN {

        if (s == 0) {

            print 0

            exit

        }

        printf "%.2f", t / s

    }'

}

############################################################
# Percent Difference
############################################################

statistics_percent_difference() {

    local baseline="$1"

    local current="$2"

    awk -v b="$baseline" -v c="$current" '

    BEGIN {

        if (b == 0) {

            print 0

            exit

        }

        printf "%.2f",

        ((c-b)/b)*100

    }'

}