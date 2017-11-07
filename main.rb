require 'twitter_oauth'
require 'net/http'
require 'uri'
require 'yaml'

class Twitter

  @@SLEEP_TIME = 1
  #
  # TwitterAPIの認証を行う
  #
  def initialize
    yaml = YAML.load_file("./config.yml")
    @twitter = TwitterOAuth::Client.new(
      :consumer_key    => yaml['consumer_key'],
      :consumer_secret => yaml['consumer_secret'],
    )
    puts "Twitter APIの認証完了"
  end

  #
  # 検索ワードに合致する写真一覧を取得
  #
  def search_pictures(word, num = 10, opt = {})
    @twitter or self.auth
    params = {
      lang:        'ja',
      locale:      'ja',
      result_type: 'mixed',
      count:       200,
    }.merge(opt)
    puts "画像検索中(残り#{num}枚)"
  
    tweets = @twitter.search(word, params)['statuses']
    puts tweets
    max_id = tweets[-1]['id']
    pictures = extract_pictures_from_tweets(tweets)
  
    if num <= pictures.count
      return pictures.take(num)
    else
      sleep @@SLEEP_TIME
      return pictures.concat self.search_pictures(word, num - pictures.count, max_id: max_id)
    end
  end

  #
  # TwitterAPIで取得したツイート一覧からmedia情報を抜き取る
  #
  def extract_pictures_from_tweets(tweets)
    pictures = tweets.map do |t|
      if media = t['entities']['media']
        media.map {|m| m['media_url']}
      else
        []
      end
    end
    pictures.flatten.uniq
  end

  #
  # ツイッター上の画像をまとめてダウンロードする
  #
  def download_pictures(word, download_dir, num = 10)
    system('mkdir',download_dir) unless Dir.exist?(download_dir)
    
    pictures = self.search_pictures(word, num)
    pictures.each_with_index do |picture, idx|
      filename = File.basename(picture)
      filepath = "#{download_dir}/#{filename}"
      open(filepath, 'wb') do |file|
        puts "downloading(#{idx + 1}/#{pictures.count}): #{picture}"
        file.puts(Net::HTTP.get_response(URI.parse(picture)).body)
      end
      sleep @@SLEEP_TIME
    end
  end
end

twitter = Twitter.new
twitter.download_pictures("hyde","./img",10)