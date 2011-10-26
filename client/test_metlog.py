#!/usr/bin/env python
from metlog.senders import ZmqPubSender
from metlog.client import MetlogClient
import time

sender = ZmqPubSender('ipc://metlog-feed')
client = MetlogClient(sender, 'testy')

while True:
    time.sleep(1)
    client.metlog('cmd', payload='come in here watson, I need you!')
