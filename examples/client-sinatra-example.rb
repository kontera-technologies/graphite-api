# ------------------------------------------------------
#  Using GraphiteAPI#client for sending metrics to our
#  Graphite server @ graphite.example.com:2003
# -----------------------------------------------------

require 'rubygems'
require 'sinatra'
require 'graphite-api'

before do
  @graphite = GraphiteAPI::Client.new(
   :graphite => "graphite.example.com:2003",
   :prefix   => ["example","prefix"],          # add example.prefix.my_app to each key
   :interval => 60                             # send to graphite every 60 seconds
  )
  
  # report server-load every 1 minute 
  @graphite.every 1.minute do |client|
    client.my_app.load_avg rand(10) # example.prefix.my_app.load_avg 12 213212332
  end
  
end

attr_reader :graphite

get '/' do
  # reporting impression
  graphite.impression 1 # example.prefix.impression 1 213212332
  
  # Going to DB to fetch some data
  db_start = Time.now
  sleep rand 22 # Running long query :)
  
  # reporting query time
  graphite.index_db_time(db_start - Time.now)
  
  # rendering ERB template
  render_start = Time.now
  page = erb :index
  
  # reporting render time 
  graphite.index_render_time(render_start - Time.now)
  
  # if everything go well
  graphite.impression_200 1
  
  # returing the page
  page
end

get '/search/article/:name' do
  articles = Article.find_all_by_name :name
  
  # reporting article search event
  graphite.metrics({
    "search_article_#{params[:name]}" => 1,
    "search_article_#{params[:name]}_results" => articles.size
  })
  
  render :search
end
