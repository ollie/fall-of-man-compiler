require 'bundler'
Bundler.require(:compiler)

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
  dir_path  = Pathname.new('data')
  file_path = dir_path.join('posts.json')

  return if file_path.file?

  posts = fetch_posts
  dir_path.mkpath
  file_path.write(MultiJson.dump(posts, pretty: true))
end

def compile_posts
  posts = MultiJson.load(File.read('data/posts.json'))
  Slim::Engine.options[:pretty] = true

  html = Tilt.new('views/light.slim').render(nil, posts: posts)
  File.write('index.html', html)
  puts 'Generated index.html'

  html = Tilt.new('views/dark.slim').render(nil, posts: posts)
  File.write('dark.html', html)
  puts 'Generated dark.html'
end

download_posts
compile_posts
