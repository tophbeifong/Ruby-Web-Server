require 'socket'

class Webserver

    def initialize

        #load settings...  
        @public_html = "www/public_html/"  
        @error_directory = "error_documents/" 

    end

    private
    def request( client_connection )

        request_data = Array.new

        while( incomming_request_data = client_connection.gets() )

            request_data.push incomming_request_data

            if(incomming_request_data == "\r\n")

                if(request_data[0][0..2] == "GET")

                    return request_data

                end

            end         

        end

        return request_data

    end

    private
    def log(type, request_data)

        log_line = "#{request_data[0]}"

    end

    private
    def return_error_document(error_type)
        case error_type
        when 404 send_file(@error_directory + "404.html")
        when 500 send_file(@error_directory + "500.html")
        else send_file(@error_directory + "default.html")
    end

    private
    def get_mime_type(file)

        #temporary
        return "text/html"

    end

    private
    def send_file(file, client_connection)

        return_error_document(404) if File.file?()

        file_data = ""

        #open file data... hard coded until settings are finished.
        File.open("#{@public_html}#{file}",'r') do |file_handle|

            while(file_line = file_handle.gets)

                file_data += file_line

            end
            
        end

        #send the file data back...
        client_connection.print "HTTP/1.1 200 OK\r\n" +
                                "Content-Type: #{get_mime_type(file)}\r\n" +
                                "Content-Length: #{file_data.bytesize}\r\n" +
                                "Connection: keep-open\r\n"

        client_connection.print "\r\n"

        client_connection.print file_data

    end

    private
    def parse_headers(request_headers)

        #get the file name of the request
        file_request = request_headers[0][5..request_headers[0].length - 12]
        
    end

    public 
    def server

        tcpwebserver = TCPServer.open(8989)

        loop do

            Thread.fork(tcpwebserver.accept) do |client_connection|

                #retrieve request headers
                request_data = request(client_connection)

                #make a log in the access.log file
                log("access", request_data)

                #send the file back...
                send_file( parse_headers(request_data), client_connection )
                

            end

        end

    end

end

run = Webserver.new
run.server()