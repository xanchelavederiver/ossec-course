#!/usr/bin/env bash
set -Eeuo pipefail
DEMO_DESCRIPTION='File permissions: ELF needs only x, a script needs r and x'
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
demo_init "$@"
need gcc python3
cleanup() { remove_users; }
new_users "$U1"

echo; echo '===== ELF: права x достаточно ====='
as "$U1" 'mkdir demo01 && cd demo01 && cp /bin/ls ./ls && chmod 0111 ls && /bin/ls -l ls'
as "$U1" 'cd demo01 && ./ls -l ls'        # исполняется без права r
as "$U1" 'cd demo01 && cat ls'            # чтение запрещено

echo; echo '===== Скрипт: нужны r и x ====='
as "$U1" 'cd demo01 && echo "/bin/ls -l" > ls.sh && chmod 0111 ls.sh && ./ls.sh'   # отказ: нет r
as "$U1" 'cd demo01 && chmod 0555 ls.sh && ./ls.sh'                                # успех
as "$U1" "cd demo01 && printf 'import os\nos.system(\"/bin/ls -l\")\n' > ls.py && chmod 0555 ls.py && ./ls.py"
as "$U1" 'cd demo01 && sed -i "1i #!/usr/bin/python3" ls.py && ./ls.py'            # шебанг решает
