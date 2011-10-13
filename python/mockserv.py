#!/usr/bin/env python

'''
This is just a dummy HTTP server to accept POST messages
'''
import sys
from wsgiref.simple_server import make_server
import webob.dec
import pprint
import json

print "Using: [%s]" % sys.version

class POSTMonitor(object):
    """
    This is a simple WSGI app that just shows some debugging
    information about what we're getting
    """
    @webob.dec.wsgify
    def __call__(self, req):
        data = json.loads(req.POST['data'])
        print '=' * 20
        msgs_received = len(data)
        print "Received %d JSON messages" % msgs_received


PORT = 8080
httpd = make_server('localhost', PORT, POSTMonitor())
print "Serving HTTP on port %s..." % PORT

# Respond to requests until process is killed
httpd.serve_forever()


