# -*- coding: utf-8 -*-

class Commit

end

class Git

  def initialize dir
    @dir = File.expand_path(dir)
  end

  def read_file path
    File.read(File.join(@dir, ".git", path))
  end

  def get_branches
    Dir.glob(@dir + "/.git/refs/heads/*").map{|path|
      File.basename(path)
    }
  end

  def to_hash
    {
      :dir => @dir,
      :branches => get_branches()
    }
  end

end


if __FILE__ == $0
  dir = ARGV[0]
  git = Git.new(dir)
  p git.to_hash
end
