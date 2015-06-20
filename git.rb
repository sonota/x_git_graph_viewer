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
    @tags = []
    @commits = []
  end

  def read_file path
    File.read(File.join(@dir, ".git", path))
  end

  def read_file_bin path
    File.binread File.join(@dir, ".git", path)
  end

  def file_path path
    File.join(@dir, ".git", path)
  end

  def get_br_cid br_name
    if File.exist?(file_path("/refs/heads/#{br_name}"))
      return read_file("/refs/heads/#{br_name}").chomp
    end

    # fallback
    # see:
    #   Git - メインテナンスとデータリカバリ
    #   https://git-scm.com/book/ja/v1/Git%E3%81%AE%E5%86%85%E5%81%B4-%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%86%E3%83%8A%E3%83%B3%E3%82%B9%E3%81%A8%E3%83%87%E3%83%BC%E3%82%BF%E3%83%AA%E3%82%AB%E3%83%90%E3%83%AA

    str = read_file("packed-refs");
    cid = nil
    str.each_line {|line|
      if %r{.+/(.+)$} =~ line
        name = $1
        if name == br_name
          /^(.+) / =~ line
          cid = $1
          break
        end
      end
    }
    raise "cid for (#{br_name}) not found" if cid.nil?
    cid
  end

  def get_tag_cid br_name
    read_file("/refs/tags/#{br_name}").chomp
  end

  def get_branches
    Dir.glob(@dir + "/.git/refs/heads/*").map{|path|
      name = File.basename(path)
      {
        :name => name,
        :cid => get_br_cid(name)
      }
    }
  end

  def get_tags
    Dir.glob(@dir + "/.git/refs/tags/*").map{|path|
      name = File.basename(path)
      {
        :name => name,
        :cid => get_tag_cid(name)
      }
    }
  end

  def to_hash
    {
      :dir => @dir,
      :branches => @branches,
      :tags => @tags,
      :commits => @commits,
      :head => @head
    }
  end

  def read_object_bin oid
    /^(..)(.+)$/ =~ oid
    index, name = $1, $2
    compressed = read_file_bin("objects/#{index}/#{name}")
    Zlib::Inflate.inflate compressed
  end

  def read_head_oid
    br_name = File.basename(read_file("HEAD").chomp)
    read_file("refs/heads/#{br_name}").chomp
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

  def load_commits_br commits, br_name
    br_head_oid = read_file("refs/heads/#{br_name}").chomp
    load_commit(commits, br_head_oid)
  end

  def load_commits_tag commits, tag_name
    tag_head_oid = read_file("refs/tags/#{tag_name}").chomp
    load_commit(commits, tag_head_oid)
  end

  def load
    @branches = get_branches()
    @tags = get_tags()
    _commits = {}
    @branches.each do |br|
      _commits = load_commits_br(_commits, br[:name])
    end
    @tags.each do |tag|
      _commits = load_commits_tag(_commits, tag[:name])
    end
    @commits = _commits.values.map{|commit|
      commit.to_hash
    }
    @head = read_head_oid()
  end

end


if __FILE__ == $0
  
  require "pp"

  dir = ARGV[0]
  git = Git.new(dir)
  git.load
  pp git.to_hash
end
