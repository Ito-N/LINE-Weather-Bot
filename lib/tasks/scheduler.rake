desc "This task is called by the Heroku scheduller add-on"
task :update_feed => :environment do
  require 'line/bot' #gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'
  require 'date'

  client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }

  #使用したxmlデータ（毎日朝６時更新）:以下URLを入力すればみれる
  url = "https://www.drk7.jp/weather/xml/13.xml"
  #xmlデータをパース（利用しやすいように整形）
  xml = open( url ).read.toutf8
  doc = REXML::Document.new(xml)
  #パスの共通部分を変数化（area[4]は「東京地方」を指定している）
  xpath = "weatherforecast/pref/area[4]/info/rainfallchance/"

  #日付を変数に代入

  #６時〜１２時の降水確率（以下同様）
  per06to12 = doc.elements[xpath + 'period[2]'].text
  per12to18 = doc.elements[xpath + 'period[3]'].text
  per18to24 = doc.elements[xpath + 'period[4]'].text
  #メッセージ
  if Date.today.wday != 5 then
    #金曜日以外
    word1 =
      ["おはようさん！いい朝だな！",
      "よく眠れたかい？今日も頑張っていこう！",
      "おはようさん！体調はどう？無理せずいこう！",
      "おはようさん！今日は良い１日になりそうだ！",
      "おはようさん！今日はゆったり過ごすのがいいかも！",
      "おはようさん！無理せず気分転換も大事だぞ！",
      "おはようさん！調子良さそうな日だ！",
      "おはようさん！最近飲み過ぎてない？",
      "おはようさん！今日はいつもと違うことをすると良いかも！",
      "おはようさん！運動でもしてリフレッシュしよう！",
      "おはようさん！明るくいこう！"].sample
    #金曜日限定のメッセージ
  else
    word1 =
        ["今日は花金！飲みに行くか！",
        "やっと金曜日だ！もう少し頑張ろう！",
        "花金だな！飲み過ぎるなよ！",
        "金曜日だ！今週も頑張ったな！",
        "待ちに待った金曜日！もう少しだ！",
        "今週ももう少し！頑張ろう！"].sample
  end

  # 降水確率によってメッセージを変更する閾値の設定
  rai_50per = 50
  rai_30per = 30
  #降水確率が高い時のメッセージ(word3は50%以上、word4は30%以上)
  if per06to12.to_i >= rai_50per || per12to18.to_i >= rai_50per || per18to24.to_i >= rai_50per then
    word2 = "今日は雨が降りそう！傘忘れるなよ！"
  elsif per06to12.to_i >= rai_30per || per12to18.to_i >= rai_30per || per18to24.to_i >= rai_30per then
    word2 = "今日は雨が降るかもな！折りたたみ傘があると安心だな"
  else
    word2 = ""
  end
  
  #発信するメッセージの設定
  push =
      "#{word1}\n今日の降水確率だぞ\n  6~12時 #{per06to12}%\n  12~18時 #{per12to18}%\n  18~24時 #{per18to24}%\n#{word2}"

  #メッセージの発信先idを配列で渡す必要あり。userテーブルよりpluck関数を使ってidを配列で取得
  user_ids = User.all.pluck(:line_id)
  message = {
    type: 'text',
    text: push
  }
  response = client.multicast(user_ids, message)

  "OK"
end
