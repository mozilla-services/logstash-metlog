import requests, json

def test_bagheera():
    """
    This test should pass if the 'demo' map is installed into bagheera
    and it is running properly on port 9080
    """
    resp = requests.post('http://localhost:9080/map/demo/', json.dumps({'foo': 'bar'}), headers={'content-type': 'application/json'})
    result = 200 <= int(resp.status_code) < 300
    assert result
    return result

print "Test is : %s" % (test_bagheera() and 'OK')
