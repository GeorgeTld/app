require 'optparse'
require 'octokit'

class Application
  VERSION = '0.0.1'

  def initialize(args)
    #client = Octokit::Client.new(:access_token => "yourTokern") if the limit of guest request is too small
    @arguments = args
  end
  
  def run
    valid_arguments? ? parse_option : raise(ArgumentError,"Wrong arguments")
  rescue ArgumentError => e
    abort "Error: #{e.message}"
  end

protected

  def valid_arguments?
    first_arg = @arguments[0]
    case @arguments.length
    when 1
      #is it an option?
      /^-/ =~ first_arg
    when 2
      #is it the option -u or --user
      /(^-u$|^--user$)/ =~ first_arg
    else
      false
    end  
  end

  def parse_option
    opts = OptionParser.new
    opts.banner = "List of options:"
    opts.on("-h", "--help") do
      puts opts
    end
    opts.on("-v", "--version") do
      puts VERSION
    end 
    opts.on("-u", "--user USER") do |user|
      favorite_language(user)
    end
     opts.parse!(ARGV)  
  end

  def favorite_language(user)
    username = get_username(user)
    list_lang = list_languages(username)
    puts "#{list_lang.max[0]} #{list_lang.max[1]}"
  rescue Faraday::ConnectionFailed => e
    abort "Connection to Github  failed, #{e.message}"
  end

  def name_repositories(user)
    repositories = Octokit.repositories(user)
    names_repo = []
    repositories.each do |repo|
      names_repo << repo.name
    end
    raise RuntimeError,"The user #{user} doesn't have any repositories" if (names_repo.empty?)
    names_repo
    rescue RuntimeError => e
      abort e.message
  end
  
  
  def get_username(user)
    user = Octokit.user(user)
    user.login
    rescue Octokit::NotFound
      abort "The user #{user} doesn't exist on Github"
  end

  def get_languages(user, repository)
    languages = Octokit.languages("#{user}/#{repository}")
  end

  def list_languages(user)
    repos = name_repositories(user)
    list_lang = {}
    repos.each do |repo|
      languages = get_languages(user,repo)
      languages.each do |lang, size|
        list_lang.has_key?(lang) ? (list_lang[lang] += size) : (list_lang[lang] = size)
      end
    end
    raise RuntimeError,"No languages could be find for the user #{user}" if list_lang.empty?
    list_lang
  rescue RuntimeError => e
    abort e.message
  end
end

app = Application.new(ARGV)
begin
app.run
rescue Octokit::TooManyRequests => e
  abort "#{e.message}\nuncomment and add your github token to the line begining with client =... in initialize method"
end
