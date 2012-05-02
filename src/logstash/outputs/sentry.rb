# 
# This module provides basic access to a Sentry server using a DSN to
# locate the server
#

require "net/http"
require "uri"
require 'time'
require 'hmac-sha1'

class SentryServer
    public 
    def initialize(dsn)
        @dsn_uri, @server_uri = compute_server_uri(dsn)
    end

    # Send an encoded message to the sentry server
    # with an optional timestamp
    public
    def send(message, timestamp)
        headers = compute_headers(message, @dsn_uri, timestamp)
        return send_message(message, headers, @server_uri)
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
        header = "Sentry sentry_timestamp=#{timestamp}, sentry_signature=#{signature}, sentry_client=#{client_id}, sentry_version=#{protocol}"
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
        req = Net::HTTP::Post.new(server_uri.path, initheader = headers)
        req.body = message
        response = Net::HTTP.new(server_uri.host, server_uri.port).start {|http| 
            http.request(req)
        }
        return response.code
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


def main()
    encoded_message = "eJzFVtuO2joU/RUrLzAq5EbCAGornd6eOlKlOe1D21HkODsZd0Ic2Q4lrfj3s22HKTClU+nckBKynbWva9nw3dN8DZlqodHeijRdXU+Ip9CSvc8bDbKkDJT/esug1Vw0CPru6b4FfPA+ghSv+IYrfPFaSiE9dN7QurNvjXsFkhQDgghJ1qLoakHynnxDXwO3KxYP+xzK2+EL1tWt5KYqT4PS2Rp0LSr/HpUxWtexZ8uVG5BZQ9c2zgfOtJBqekXZCyHupn9w6dcC0QZbwwZqRCUhGvjc6IwXxmuWpIsoipMcCppEkNNFNGdhsoDiEpIULo0zuwV2p7q1wTNWJAks6TJhUQnJIg1n+WxRFMt0kS7ZMjV42GpJzcR2942qvam4hh8Tb6X4Asw0G6FlOFGarluTKA6jeBom01n4Z7RcpfEqDP3LZTqPZx+9n3J1rSm7w8QMLFmlxLmYtJ/wuWvYwKIbalt3FW9UxkRT8srEo7nKWqpvDSR4j6NVwcYOtKmCAjaBo2EqKc5uMDJnmIAqOOSq7T3bG5j4GqdhqvDI8JGgO9mQE0LH/YRsJySJL4yvuQwWW1x5N1Zd0o7QY2WVaRvR+9wYyCeX9MZZOJYCNcFqqhR5RoaC3KryX0HeVS9piwXAtV373BxFGQbjOhtCIkcbjtBnh1379j7AV26Mg+W8nA6ONYs1P91Tcdo/oZqE2yhMYA6zOHz+0D/6lX906B8lzv+LcpQ/dRokI7MwIqUUazIKrnulYR285bmksg/eGL18FfJOBe96fSsav9yvBB9weGaDBrE/D2qeB61FGMuEDLKMN1xnGTLPRjY1q7k7WjC548Ct+FfWemkNInKj/oPS41kUHvhnptTMKGiv1KMRnAHdx2PzeR4tnnu7o/PmQKkmU8lr2B8hZ6UslH6gZUfAai9V8xl6tNoYj5TAIxaDVMMhNbqwUh7iZDVvbNK98wmh43RCUrsZDLARCF3OsJPj3Xwqkf9jJ1PyhOR4MRKQMSVTkh/t4QLKB73hTu8vTnZ2j3fs2dsO339r9/zzlD84ks7x+Dvn2w9Kw0cojf87Sp168dQ8s6/Gw9k7ISMXa/QIz/GYTkg+IeyUajpQzMwvcowPuVn49zh7RIKPMHlG3/ccLi53N7Z2UIpWP/+HtCK/8bdo9xdIJx+H"
    dsn = "http://fadb4a747d0543d187941cc191299619:df3a2cca09ba411e8f444f94b9305045@localhost:9000/1"
    #
    # Get the current timestamp
    timestamp = Time.now.to_f

    sender = SentryServer.new(dsn)
    response_code = sender.send(encoded_message, timestamp)
    puts "Got sentry status: [#{response_code}]"
end
