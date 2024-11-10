# 
class Bookfile
  attr_accessor :_stru
  def self.read_file(name)
    cnt = File.read(name)
    
  end

  def self.scan(path)
    Dir.glob(path+"/*").each do |file|
      cfg = file.scan(/_config.yml/)
      cover = file.scan(/_cover\.\w+/)

    end
  end
end
