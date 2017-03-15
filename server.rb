require 'socket'
require 'daemons'

class Server

  attr_reader :default_port
  attr_reader :default_public_directory
  attr_reader :current_directory
  attr_reader :default_file

  def initialize(default_port = 9090)
    @default_port = default_port
    @current_directory = File.expand_path(File.dirname(__FILE__))
    @default_public_directory = "public_html/"
    @default_file = "/index.html"
    @default_error_directory = "#{@current_directory}/www/#{@default_public_directory}error_documents/"
  end

  private
  def access_log(filename, client_connection)
    connection_port, connection_origin = Socket.unpack_sockaddr_in(client_connection.getpeername)
    current_time = Time.now
    #export to "access.log" and return
    access_string = "[#{connection_origin}] Document request \"#{filename}\" at [#{current_time}]"
    access_file = File.open("#{@current_directory}/www/logs/access.log","a") do |access|
      access.puts access_string
    end
  end

  private
  def mime_type(filename)

    return "text/html; utf-8" if(open_directory(filename))

    return content_type = true_mime_type = `file --mime -b #{@current_directory}/www/#{@default_public_directory}#{filename}`.chomp
  end

  private
  def error_page(error_file, filename)
    
    puts "Error detected \"#{error_file}\" sending error file #{error_file}.html"
    if File.exists? (@default_error_directory + error_file + ".html")
  
      return File.read("#{@default_error_directory}#{error_file}.html")
    
    else

      return File.read("#{@default_error_directory}default.html")
    
    end
    
  end

  private
  def return_dynamic_file(dir_name)

    #html template for open directory view
    document_top = '<!doctype html><html><head><title>' + dir_name + '</title></head><body><h1>Viewing: ' + dir_name + '</h1><hr /><ul>'
    document_content = ''
    document_bot = '</ul><hr /><p><i>Ruby WebServer 2.0.1 - Beta: ' + @current_directory + '/www/public_html/' + dir_name + '</i></p></body></html>'

    #get all files/folders withing a directory
    files_and_docs = Dir.entries("#{@current_directory}/www/public_html/#{dir_name}")

    #loop through and append
    for f in files_and_docs.reverse

      document_content += '<li><a href="' + f + '">' + f + '</a></li>'
          
    end

    #return dynamic source
    return document_top + document_content + document_bot

  end

  private
  def get_local_file(filename, client_connection)

    #create entry into the access log
    access_log(filename, client_connection)
    
    #check if its a directory
    if open_directory(filename)
      
      begin

        #return the dynamic directory source
        return return_dynamic_file(filename)
        
      rescue(StandardError file_open_error)

        #create an error/show 500
        error_page("500", filename)
        puts "Error delivering #{filename}"

      end

    else

      puts "Fetching document: #{@current_directory}/www/#{@default_public_directory}#{filename}"

      #return 404
      return error_page("404",filename) unless File.exists? ("#{@current_directory}/www/#{@default_public_directory}#{filename}")

      #return page source
      return File.read("#{@current_directory}/www/#{@default_public_directory}#{filename}")

    end
    
  end

    private
    def request( client_connection )

        request_data = Array.new

        while( incomming_request_data = client_connection.gets() )

            request_data.push incomming_request_data
            puts incomming_request_data

            if(incomming_request_data == "\r\n")

                if(request_data[0][0..2] == "GET")

                    return request_data

                end

            end         

        end

        return request_data

    end

    private
    def parse_headers(request_headers)

        #get the file name of the request
        file_request = request_headers[0][5..request_headers[0].length - 12]

        if (file_request == "")

            return "index.html"

        end

        filename = ""

        #enable GET requests
        if file_request.include? "?"

            for i in 0..file_request.length

                if file_request[i] != "?"

                    filename += file_request[i]

                else

                    return filename

                end

            end

        end

        return file_request
        
    end

  private
  def open_directory(filename)
    return true if File.directory? ("#{@current_directory}/www/#{@default_public_directory}#{filename}")
    return false

  end


  public
  def listen
    Daemons.run_proc("Ruby WebServer Running") do
      begin
        connection = TCPServer.new(@default_port)
        loop do
          Thread.start(connection.accept) do |client_connection|

            #get the full request
            incomming_data = request(client_connection)

            #get the filename from the headers, 
            #can be modded for extra information later on it needed
            filename = parse_headers(incomming_data)

            #check if its a directory and contains index file or send diectory

            #get the source from the requested file
            source = get_local_file(filename, client_connection)

            puts "Sending #{filename}...\n\n"

            content_type = mime_type(filename)

            #send the data back to the browser
            client_connection.print "HTTP/1.1 200 OK\r\n" +
                                   "Content-Type: #{content_type}\r\n" +
                                   "Content-Length: #{source.bytesize}\r\n" +
                                   "Connection: close\r\n"
            client_connection.print "\r\n"

            client_connection.print source
          end
        end
      rescue StandardError
        return puts "Error creating TCPServer."
      end
    end
  end
end

connection = Server.new(9090) 
connection.listen 