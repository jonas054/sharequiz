require 'find'

$tarfile = 'sq.tar.gz'

def file_list(tar_time = nil)
  cmd = "tar zcvf #{$tarfile}"
  %w(app config public db).each { |dir|
    Find.find(dir) { |path|
      case path
      when %r"/\.svn", %r"/Flags", %r"Thumbs.db"
        Find.prune
      else
        if tar_time.nil? or File.mtime(path) > tar_time
          cmd += " " + path unless File.directory?(path)
        end
      end
    }
  }
  cmd
end

def update_tar_file
  file_list File.mtime($tarfile)
end

if __FILE__ == $0
  case ARGV.first
  when '-c' then puts file_list
  when '-u' then puts update_tar_file
  else puts "Usage: ruby #$0 -c|-u"
  end
end