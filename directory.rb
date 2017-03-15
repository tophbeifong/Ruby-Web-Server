document_name = ARGV[0]

o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
string = (0...10).map { o[rand(o.length)] }.join

random_doc_name = "tmp_" + string + ".html"

document_top = '<!doctype html>
<html>
    <head>
        <title>' + document_name + '</title>
    </head>
    <body>
        <h1>Viewing: ' + document_name + '</h1>
        <hr /><ul>'


document_bot = '</ul>
</body>
</html>'

files_and_docs = Dir.entries("#{File.expand_path(File.dirname(__FILE__))}/www/public_html/#{document_name}")

File.open("#{File.expand_path(File.dirname(__FILE__))}/www/tmp/#{random_doc_name}","w") do |file|
    file.write document_top

        for f in files_and_docs

            file.write '<li><a href="' + f + '">' + f + '</a></li>'
        
        end

    file.write document_bot
end

puts random_doc_name