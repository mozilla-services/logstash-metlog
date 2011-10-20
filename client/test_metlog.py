#!/usr/bin/env python
from metlog.senders import ZmqPubSender
from metlog.client import MetlogClient
import time

sender = ZmqPubSender('tcp://127.0.0.1:5565')
client = MetlogClient(sender, 'testy')

while True:
    time.sleep(1)
    client.metlog('cmd', payload='come in here watson, I need you!')
