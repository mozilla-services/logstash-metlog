# 
# This module provides basic access to a Sentry server using a DSN to
# locate the server
#
# TODO: these don't really need to be instances.  Just use static
# methods

require "net/http"
require "uri"
require 'time'
require 'logstash/util/hmac/hmac-sha1'


class BaseClient
    public 
    def initialize(dsn, err_queue)
        @dsn_uri, @server_uri = compute_server_uri(dsn)
        @err_queue = err_queue
    end

    # Send an encoded message to the sentry server
    # with an optional timestamp
    public
    def send(event)
        message = event['payload']
        timestamp=  event['fields']['epoch_timestamp']

        headers = compute_headers(message, @dsn_uri, timestamp)

        result = send_message(message, headers, @server_uri).to_i

        # Anything that's not HTTP 20x, push the event back
        if (result < 200 or result > 299)
            @err_queue.push(event)
        end

        return result
    end

    private
    def compute_server_uri(dsn)
        uri = URI.parse(dsn)
        path_bits = uri.path.split('/', 2)
        if path_bits.length > 1
            path = path_bits[0]
        else
            path = ''
        end
        project = path_bits[-1]

        netloc = uri.host
        if (uri.scheme == 'http' and uri.port and uri.port != 80) or (uri.scheme == 'https' and uri.port and uri.port != 443)
            netloc += ":#{uri.port}"
        end

        if not netloc and project and uri.username and uri.password
            raise ArgumentError, "Invalid Sentry DSN: #{dsn}"
        end

        server_uri = URI.parse("#{uri.scheme}://#{netloc}#{path}/api/store/")
        return uri, server_uri
    end

    private
    def get_auth_header(protocol, signature, timestamp, client_id, api_key)
        header = "Sentry sentry_timestamp=#{timestamp}, sentry_client=#{client_id}, sentry_version=#{protocol}"
        if api_key
            header = header + ", sentry_key=#{api_key}"
        end
        return header
    end

    private
    def get_signature(message, timestamp, key)
        return HMAC::SHA1.new(key.to_s).update("#{timestamp} #{message}").hexdigest
    end

    private
    def send_message(message, headers, server_uri)
        raise NotImplementedError, "Subclasses must implement this"
    end

    # Compute the headers for a given message and the DSN URI
    private
    def compute_headers(message, uri, timestamp)
        key = uri.password
        client_version = 1.0

        headers = {
            'X-Sentry-Auth' => get_auth_header(
                protocol=2.0,
                signature=get_signature(message, timestamp, key),
                timestamp=timestamp,
                client_id="raven-logstash/#{client_version}",
                api_key=uri.user
            ),
            'Content-Type' => 'application/octet-stream',
        }
        return headers
    end
end

class HTTPClient < BaseClient
    def send_message(message, headers, server_uri)
        req = Net::HTTP::Post.new(server_uri.path, initheader = headers)
        req.body = message
        begin
            response = Net::HTTP.new(server_uri.host, server_uri.port).start {|http| 
                http.request(req)
            }
            return response.code
        rescue Errno::ECONNREFUSED => e
            return 503 # Service Unavailable
        else
            return 500 # Something weird happend
        end
    end
end

class UDPClient < BaseClient
    public 
    def initialize()
    end

    # Send an encoded message to the sentry server
    # with an optional timestamp
    public
    def send(event)
        message = event['payload']
        timestamp = event['fields']['epoch_timestamp']
        dsn = event['fields']['dsn']

        dsn_uri, server_uri = compute_server_uri(dsn)

        headers = compute_headers(message, dsn_uri, timestamp)

        send_message(message, headers, server_uri).to_i
    end

    private
    def compute_server_uri(dsn)
        uri = URI.parse(dsn)
        return uri, uri
    end

    private
    def send_message(message, headers, server_uri)
        auth_header = headers['X-Sentry-Auth']

        if auth_header == nil
            # TODO: we should really do something with the error queue
            # instead of just silently eating errors
            return
        end

        udp_socket = UDPSocket.new
        udp_socket.send("#{auth_header}\n\n#{message}", 0, server_uri.host, server_uri.port)
    end
end


def main()
    encoded_message = "eJzFVtuO2joU/RUrLzAq5EbCAGornd6eOlKlOe1D21HkODsZd0Ic2Q4lrfj3s22HKTClU+nckBKynbWva9nw3dN8DZlqodHeijRdXU+Ip9CSvc8bDbKkDJT/esug1Vw0CPru6b4FfPA+ghSv+IYrfPFaSiE9dN7QurNvjXsFkhQDgghJ1qLoakHynnxDXwO3KxYP+xzK2+EL1tWt5KYqT4PS2Rp0LSr/HpUxWtexZ8uVG5BZQ9c2zgfOtJBqekXZCyHupn9w6dcC0QZbwwZqRCUhGvjc6IwXxmuWpIsoipMcCppEkNNFNGdhsoDiEpIULo0zuwV2p7q1wTNWJAks6TJhUQnJIg1n+WxRFMt0kS7ZMjV42GpJzcR2942qvam4hh8Tb6X4Asw0G6FlOFGarluTKA6jeBom01n4Z7RcpfEqDP3LZTqPZx+9n3J1rSm7w8QMLFmlxLmYtJ/wuWvYwKIbalt3FW9UxkRT8srEo7nKWqpvDSR4j6NVwcYOtKmCAjaBo2EqKc5uMDJnmIAqOOSq7T3bG5j4GqdhqvDI8JGgO9mQE0LH/YRsJySJL4yvuQwWW1x5N1Zd0o7QY2WVaRvR+9wYyCeX9MZZOJYCNcFqqhR5RoaC3KryX0HeVS9piwXAtV373BxFGQbjOhtCIkcbjtBnh1379j7AV26Mg+W8nA6ONYs1P91Tcdo/oZqE2yhMYA6zOHz+0D/6lX906B8lzv+LcpQ/dRokI7MwIqUUazIKrnulYR285bmksg/eGL18FfJOBe96fSsav9yvBB9weGaDBrE/D2qeB61FGMuEDLKMN1xnGTLPRjY1q7k7WjC548Ct+FfWemkNInKj/oPS41kUHvhnptTMKGiv1KMRnAHdx2PzeR4tnnu7o/PmQKkmU8lr2B8hZ6UslH6gZUfAai9V8xl6tNoYj5TAIxaDVMMhNbqwUh7iZDVvbNK98wmh43RCUrsZDLARCF3OsJPj3Xwqkf9jJ1PyhOR4MRKQMSVTkh/t4QLKB73hTu8vTnZ2j3fs2dsO339r9/zzlD84ks7x+Dvn2w9Kw0cojf87Sp168dQ8s6/Gw9k7ISMXa/QIz/GYTkg+IeyUajpQzMwvcowPuVn49zh7RIKPMHlG3/ccLi53N7Z2UIpWP/+HtCK/8bdo9xdIJx+H"

    dsn = "http://2cfcac6f616e4a90b20f4aed9f0e40dc:9a813d742a51426c9285e8222c2a65b7@192.168.20.2:9000/2"
    #
    # Get the current timestamp
    timestamp = Time.now.to_f

    err_queue = Queue.new

    sender = HTTPClient.new(dsn, err_queue)
    response_code = sender.send({"payload" => encoded_message, 
                                 "fields" => {"epoch_timestamp" => timestamp}})
    puts "Got sentry status: [#{response_code}]"
end

def udp_main()
    # Raven encodes the project ID into the base64 blob as well as
    # the DSN. 
    # The following blob encodes a project ID of 2
    encoded_message = """eJztV1tv2zYU/iuEXpwMta7WzcuCdVse8rB2aLICa1MIFEXZXCRSJSkvXpH/vkNSTpykxdZhXfJQBHCoo3Pndz6KH7xBit8p0d4SebH3DHmKci23PuOayhYTqvyTK0IHzQQHnQ+e3g7UKL+hUvzENkzBixMphTTGG9yN9q0xX1GJmkkDCYl60YydQPUW/Qm2Rt1KrD7dxVDeNbwgYzdIZpOqqh4zXlX+kdM+dknKDZUVx721fs2IFlLNf8bkByEu58+Z9DtBcGd0NV4pUOJj18ET3UB9FWts0DBLCU0LQkm2oIu0wEXaJCTN87pJ27g21mRNyaUae9ufrEnLYpGEWVa2WUFpjos4KaM4xwuSN5nRp1daYtOo65v61O5RMU1vM9Gsp5UaIJ27MqVxP9hwYRTPw3IeZ+dRsUySZRy++fgOnWlMLiEuoXaLWgl9MVHfwnrkZNo7b7+DuFbVgPXaytmw1WvB54wPo55n86iFtqRQEU2bY7ev0lbhVY2xeOsFv8IWqGBjG89XQUM3QSdWkLtaz3uqYR0oSW5kgRg1+Fbeu2dmS01U43dNO1vqOYAKmYeDQ9QCVGxtGBLfOPEzgx/7XtQGrU7LCBCuwTVyYt+z3uuRddpgZq9oNNuTz9CBXUPBh7a+ikVGt5WiRxIDRBDrByE1+sa8fT86KB6d/mL75BMhqY9HbSDWwXww/Xx6mBJBWKPwKgrrrMVlFE4xMuMEtm55wRGKUIDCC+6AbyXEJ3jQo6Q3A3dw6AxTY0jQd+jHjsHmH1x4YzMsg4AmBCdtTWhd5wucU5zEOS2LpG2LOFsUyTKMkixty7zNabKo87xoSB0WUZpjUuZZXH9vp2QtlF6WYRgFDlpBfOFNkRcPIpu/Lx/9gttI7hf+f+vSSZ5EOlNv4l0y6AsnYMJ1AlvOOtoNNDKSW5yVizIpHM5grsklXlGL/x3tXf0XEF5RoE7HFdYZjB5vEIz7WjTonMqecdyd3s7uGUxo5+9ZIdGimxRg2kCVN76eLP29sVfW9FM+H+ZIozQ8nubssaalagRxpGN62WPNTD+3iEiKNW3QxESGuqYe3CE6yjcMWtKbE2Gfx9RnEZnjZ7P+BJv9X4h9GmP66FlM3PUIePzMk8aczK9PXp2dvnxhvz780M8cDs1nlsPg7mPMyW+O8duFWt+B6h22UWvciD+4miGLzNn9bwgf4K9H3MEcqODs5MX5q9+CjtWBo47YzwLzATWf2E0Fk/PAOA92zv1hS2Z2FIjNxOLfr7Givmv/fepok7Qsdyc0e8gdj4Zcl4EtgnRYKTR7UMtsl/aTyHpC+in/ykBfGejfMlAl1rvr0stR2+XtTeo+BbUMyGK6A/79JaZjnHIBuvH1O+Ozg7tgB4+L0ASgSgGrfPRmu0T/4Dp7/RchnrHr"""

    dsn = "udp://e3ca3fbcebb74a7ea327e983ff826483:01365f97f7e34b778dcb08157ac9762b@localhost:9001/sentry/2"

    # Get the current timestamp
    timestamp = Time.now.to_f

    err_queue = Queue.new

    sender = UDPClient.new(err_queue)
    sender.send({"payload" => encoded_message, 
                 "fields" => {"epoch_timestamp" => "some_timestamp",
                              "dsn" => dsn }})
    puts "Sent!"
end

