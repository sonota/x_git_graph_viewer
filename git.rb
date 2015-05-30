# -*- coding: utf-8 -*-

require "zlib"

class Commit

  attr_accessor :oid, :parents, :msg, :committer, :author

  def initialize
    @parents = []
  end

  def to_hash
    {
      :oid => @oid,
      :parents => @parents,
      :msg => @msg,
      :committer => @committer,
      :author => @author
    }
  end

  def self.parse str
    c = Commit.new
    str.each_line{|line|
      case line
      when /^parent (.+)/    ; c.parents << $1
      when /^committer (.+)/ ; c.committer = $1
      when /^author (.+)/    ; c.author = $1
      end
    }

    msg = str.split("\n\n")[1]
    c.msg = msg
    c
  end

end

class Git

  def initialize dir
    @dir = File.expand_path(dir)
    @branches = []
    @commits = []
  end

  def read_file path
    File.read(File.join(@dir, ".git", path))
  end

  def read_file_bin path
    File.binread File.join(@dir, ".git", path)
  end

  def get_branches
    Dir.glob(@dir + "/.git/refs/heads/*").map{|path|
      File.basename(path)
    }
  end

  def to_hash
    {
      :dir => @dir,
      :branches => @branches,
      :commits => @commits
    }
  end

  def read_object_bin oid
    /^(..)(.+)$/ =~ oid
    index, name = $1, $2
    compressed = read_file_bin("objects/#{index}/#{name}")
    Zlib::Inflate.inflate compressed
  end
  
  def load_commit commits, oid
    if oid.nil? || commits.has_key?(oid)
      return commits
    end

    bin = read_object_bin(oid)
    /\A(.+?)\x00(.+)\Z/m =~ bin
    head, body = $1, $2

    c = Commit.parse(body)
    c.oid = oid
    commits[oid] = c
    
    commits = load_commit(commits, c.parents[0])
    commits = load_commit(commits, c.parents[1])
    
    commits
  end

  def load_commits br_name
    br_head_oid = read_file("refs/heads/#{br_name}").chomp
    load_commit({}, br_head_oid)
  end

  def load
    @branches = get_branches()
    commits_hash = {}
    @branches.each do |br_name|
      temp = load_commits(br_name)
      commits_hash.merge! temp
    end
    @commits = commits_hash.values.map{|commit|
      commit.to_hash
    }
  end

end


if __FILE__ == $0
  
  require "pp"

  dir = ARGV[0]
  git = Git.new(dir)
  git.load
  pp git.to_hash
end
