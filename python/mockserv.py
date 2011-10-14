#!/usr/bin/env python

'''
This is just a dummy HTTP server to accept POST messages
'''
from wsgiref.simple_server import make_server
import argparse
import json
import pprint
import sys
import webob.dec

print "Using: [%s]" % sys.version

PORTS = {'test1': 9080,
         'test2': 8090,}

def parse_args():
    parser = argparse.ArgumentParser(description="Download tool to fetch files for MARVEN")

    parser.add_argument("--test1",
            action='store_true',
            help="Run as testserver 1")

    parser.add_argument("--test2",
            action='store_true',
            help="Run as testserver 2")


    return parser.parse_args()


class POSTMonitor(object):
    """
    This is a simple WSGI app that just shows some debugging
    information about what we're getting
    """
    def __init__(self):
        self._counter = 0

    @webob.dec.wsgify
    def __call__(self, req):
        # TODO: change this to read the raw POST data
        data = json.loads(req.body)
        print '=' * 20
        msgs_received = len(data)
        self._counter += msgs_received
        print "Received %d JSON messages" % msgs_received
        print "Total message received: %d" % self._counter
        pprint.pprint(data)


def main():
    args = parse_args()
    for k in PORTS.keys():
        if getattr(args, k):
            port = PORTS[k]

    httpd = make_server('localhost', port, POSTMonitor())
    print "Serving HTTP on port %s..." % port

    # Respond to requests until process is killed
    httpd.serve_forever()

if __name__ == '__main__':
    main()
