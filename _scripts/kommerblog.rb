#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'json'
require 'yaml'

# The archive page only renders the newest posts (the rest are lazy-loaded),
# so fetch all posts via the WordPress REST API instead.
API_URL = "https://gerd-kommer.de/wp-json/wp/v2/posts?per_page=100&_fields=link,title,categories"
SECRET_CATEGORY_ID = 65 # hidden posts that do not appear in the public archive

posts = []
page = 1
loop do
  response = URI.open("#{API_URL}&page=#{page}")
  posts.concat(JSON.parse(response.read))
  break if page >= response.meta["x-wp-totalpages"].to_i
  page += 1
end

articles = posts.reject { |post| post["categories"].include?(SECRET_CATEGORY_ID) }.map do |post|
  {
    "title" => Nokogiri::HTML.fragment(post["title"]["rendered"]).text.strip,
    "link"  => post["link"]
  }
end.sort_by { |article| article["title"] }

File.open("_data/kommer_articles.yml", "w") do |file|
  file.write(articles.to_yaml)
end
