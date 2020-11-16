require 'bundler'
Bundler.require(:default, :compiler)

require 'yaml'

USER_AGENT = 'ruby:The-Fall-of-Man-Compiler:0.0.1 (by /u/vetesnik)'.freeze

def config
  @config ||= begin
    config_path = Pathname.new('config/reddit.yml')
    abort 'Cannot find config/reddit.yml' unless config_path.file?
    YAML.safe_load(config_path.read)
  end
end

def run_request(request)
  puts request.url
  response = request.run

  raise "Error #{request.url} #{response.body} (#{response.code})" unless response.success?

  response
end

def access_token
  @access_token ||= begin
    if !config['username']      || config['username'].empty?  ||
       !config['password']      || config['password'].empty?  ||
       !config['client_id']     || config['client_id'].empty? ||
       !config['client_secret'] || config['password'].empty?
      abort 'Please fill in Reddit credentials in config/reddit.yml'
    else
      request = Typhoeus::Request.new(
        'https://www.reddit.com/api/v1/access_token',
        method: :post,
        userpwd: "#{config['client_id']}:#{config['client_secret']}",
        headers: {
          'User-Agent' => USER_AGENT
        },
        body: {
          grant_type: 'client_credentials',
          username: config['username'],
          password: config['password']
        }
      )

      response = run_request(request)
      sleep 1
      data = MultiJson.load(response.body)
      data.fetch('access_token')
    end
  end
end

def fetch_posts
  posts = []
  after = nil

  loop do
    request = Typhoeus::Request.new(
      'https://oauth.reddit.com/r/ThePhenomenon/search',
      headers: {
        'User-Agent'    => USER_AGENT,
        'Authorization' => "bearer #{access_token}"
      },
      params: {
        q: '"Fall of Man" author:Emperor_Cartagia',
        sort: 'new',
        restrict_sr: true,
        raw_json: 1,
        t: 'all',
        type: 'link',
        show: 'all',
        after: after
      }
    )

    response = run_request(request)
    data     = MultiJson.load(response.body)
    listing  = data.fetch('data')

    listing.fetch('children').each do |post|
      unless post.fetch('data').fetch('title').match?(/Fall of Man \d+:/i)
        puts "Ignoring #{post.fetch('data').fetch('title').inspect}"
        next
      end
      data       = post.fetch('data')
      title      = data.fetch('title')
      created_at = Time.at(data.fetch('created_utc')).utc.strftime('%B %-d, %Y')

      match = title.match(/\s+(?<number>\d+):\s*(?<title>.*)/)

      abort "Unrecognized title: #{title.inspect}" unless match

      posts << {
        full_title: title,
        number:     match[:number].to_i,
        title:      match[:title],
        created_at: created_at,
        url:        data.fetch('url'),
        body:       data.fetch('selftext_html')
      }
    end

    after = listing.fetch('after')
    break unless after

    sleep 1
  end

  posts.reverse!
end

def download_posts
  dir_path = Pathname.new('data/fall-of-man')
  file_paths = Pathname.glob('data/fall-of-man/*.json')

  return if file_paths.any?

  posts = fetch_posts

  dir_path.mkpath

  posts.each do |post|
    file_name = post.fetch(:number).to_s.rjust(3, '0')
    file_path = dir_path.join("#{file_name}.json")
    file_path.write(MultiJson.dump(post, pretty: true))
  end
end

class Helpers
  def version_asset(path)
    file_path = Pathname.new(path)

    return path unless file_path.file?

    "#{path}?v=#{file_path.mtime.to_i}"
  end
end

def generate_index(posts, view:, file_name:, dark:)
  Slim::Engine.options[:pretty] = true
  file_name << '.html' unless file_name.end_with?('.html')
  html = Tilt.new("views/#{view}.slim").render(
    Helpers.new,
    posts: posts,
    dark: dark
  )
  File.write(file_name, html)
  puts "Generated #{file_name}"
end

def compile_fall_of_man_posts
  file_paths = Pathname.glob('data/fall-of-man/*.json').sort
  posts = file_paths.map { |file_path| MultiJson.load(file_path.read) }
  generate_index(posts, view: :fall_of_man, file_name: 'index', dark: false)
  generate_index(posts, view: :fall_of_man, file_name: 'dark', dark: true)
end

def compile_the_phenomenon_posts
  file_paths = Pathname.glob('data/the-phenomenon/*.json').sort
  posts = file_paths.map { |file_path| MultiJson.load(file_path.read) }
  generate_index(posts, view: :the_phenomenon, file_name: 'the-phenomenon', dark: false)
  generate_index(posts, view: :the_phenomenon, file_name: 'the-phenomenon-dark', dark: true)
end

download_posts
compile_fall_of_man_posts
compile_the_phenomenon_posts
