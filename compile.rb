require 'bundler'
Bundler.require(:default, :compiler)

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

compile_fall_of_man_posts
compile_the_phenomenon_posts
