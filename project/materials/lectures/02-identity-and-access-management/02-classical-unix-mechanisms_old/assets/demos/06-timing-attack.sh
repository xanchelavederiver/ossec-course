#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
if [[ ${1:-} == --help ]]; then printf 'bash 06-timing-attack.sh: local synthetic timing oracle; no root/network\n'; exit 0; fi
[[ $# == 0 ]] || die 'Unsupported argument'
need python3
printf '$ python3  # embedded timing experiment, amplified with sleep(0.002)\n'
python3 - <<'PY'
import hmac, statistics, time
secret = b'cabdab'
alphabet = b'abcd'
def vulnerable(candidate):
    for a, b in zip(candidate, secret):
        if a != b:
            return False
        time.sleep(.002)  # artificial amplification, NOT how login compares passwords
    return len(candidate) == len(secret)
def sample(candidate):
    start = time.perf_counter_ns()
    vulnerable(candidate)
    return (time.perf_counter_ns() - start) / 1e6
prefix = b''
for i in range(len(secret)):
    scores = {}
    for char in alphabet:
        candidate = prefix + bytes([char]) + b'?' * (len(secret) - i - 1)
        scores[char] = statistics.median(sample(candidate) for _ in range(7))
    prefix += bytes([max(scores, key=scores.get)])
    print(f'prefix={prefix.decode()} max_median_ms={max(scores.values()):.2f}')
print('Recovered:', prefix == secret)
assert prefix == secret, 'Noise dominated the measurement; repeat on an idle VM'
print('compare_digest(correct):', hmac.compare_digest(secret, secret))
print('compare_digest(wrong):', hmac.compare_digest(b'xxxxxx', secret))
print('Use equal-length derived hashes; this demo is not an attack on PAM.')
PY
