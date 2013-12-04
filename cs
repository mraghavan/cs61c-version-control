#!/usr/local/bin/python3

import sys
import os
import subprocess

USAGE="Usage: cs"

bash_func_map = {
    'done-server': 'done_using_server',
    'get': 'get61c',
    'lookup': 'lookup61c',
    'pull': 'pull61c',
    'push': 'push61c',
    'submit': 'submit61c',
    'update-server': 'update_server',
    'use-server': 'use_server',
    }

def bash_call(func, args):
    source = 'source ' + os.path.dirname(os.path.realpath(__file__)) + '/cs.sh'
    base_cmd = ['/bin/bash', '-c', source + ' && ' + func]
    for arg in args:
        base_cmd[2] += ' ' + arg
    return subprocess.call(base_cmd)

def str_list(l):
    s = ''
    for elem in l:
        s += str(elem) + ' '
    return s[:-1]

def main(argv):
    if len(argv) == 0:
        print(USAGE, file=sys.stderr)
        return
    cmd = argv[0]
    ret = 0
    if cmd in bash_func_map:
        ret = bash_call(bash_func_map[cmd], argv[1:])
    elif cmd in ('help', '--help', '-h'):
        docs = os.path.dirname(os.path.realpath(__file__)) + '/docs/cs_doc'
        doc_file = open(docs, 'r')
        print(doc_file.read())
        doc_file.close()
    else:
        print('cs: unknown argument ' + cmd, file=sys.stderr)
    if ret != 0:
        print('cs: could not execute "' + str_list(argv) + '"', file=sys.stderr)
    return

if __name__ == '__main__':
    main(sys.argv[1:])
