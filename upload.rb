# This program was used when ShareQuiz ran on Binero. Now that it's on Heroku,
# deployment is done with git instead.

require 'rubygems'
require 'find'
require 'zip/zip'
require 'net/ssh'
require 'net/ftp'

def file_list(filename, zip_time)
  Zip::ZipFile.open(filename, Zip::ZipFile::CREATE) { |zipfile|
    %w(app config public db).each { |dir|
      Find.find(dir) { |path|
        case path
        when %r"/\.svn", %r"/Flags"
          Find.prune # directories we don't want in the zip file
        when /(Thumbs\.db|database\.yml|dispatch\.\w+|schema\.rb)$/
          next # files we don't want in the zip file
        else
          if (zip_time.nil? or File.mtime(path) > zip_time) and !File.directory?(path)
            puts path
            zipfile.get_output_stream(path) { |stream|
              File.open(path, "rb") { |f| stream << f.read until f.eof? }
            }
          end
        end
      }
    }
  }
end

HOST, USER, PASSWORD = %w(ssh.sharequiz.com web27402 duyd94utdj)
DIR, ZIP_FILE = %w(domains/sharequiz.com/sharequiz sq.zip)

if File.exists? ZIP_FILE
  time = File.mtime ZIP_FILE
  File.delete ZIP_FILE
end
file_list ZIP_FILE, time

Net::FTP.open(HOST, USER, PASSWORD) { |ftp|
  ftp.chdir DIR
  ftp.put ZIP_FILE
}

Net::SSH.start(HOST, USER, :password => PASSWORD) { |ssh|
    puts ssh.exec!("cd #{DIR}; unzip -o #{ZIP_FILE}")
    puts ssh.exec!("cd #{DIR}; rake db:migrate")
}
