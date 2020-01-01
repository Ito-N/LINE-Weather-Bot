require 'test_helper'

class LinebotControllerTest < ActionDispatch::IntegrationTest
  require 'line/bot' #gem 'line-bot-api'
  require 'open-uri'
  require 'kconv'
  require 'rexml/document'

  #callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each {|event|
      case event

      #メッセージが送信された場合の対応(機能①)
      when Line::Bot::Event::Message
        case event.type
          #ユーザーからテキスト形式のメッセージが送られてきた場合
        when Line::Bot::Event::MessageType::Text
          # event.message['text']ユーザーから送られたメッセージ
          input = event.message['text']
          url ="ttps://www.drk7.jp/weather/xml/13.xml"
          xml = open(url).read.toutf8
          doc = REXML::Document.new(xml)
          xpath = 'weatherforecast/pref/area[4]/'

          #明日・明後日のメッセージに対する返答
          case input
          rai_50per = 50
            #「明日」or「あした」というワードが含まれる場合
          when /.*(明日|あした).*/
            # info[2]:明日の天気
            per06to12 = doc.elements[xpath + 'info[2]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[2]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[2]/rainfallchance/period[4]'].text

            #降水確率50%以上か否か
            if per06to12.to_i >= rai_50per || per12to18.to_i >= rai_50per || per18to24.to_i >= rai_50per then
              push = "明日は雨が降りそうだな。。\n降水確率はこうなっているぞ\n  6~12時 #{per06to12}%\n  12~18時 #{per12to18}%\n  18~24時 #{per18to24}%\nいつでも聞いておくれ！"
            else
              push = "明日は雨は降らない予定だな！。\n降水確率はこうなっているぞ\n  6~12時 #{per06to12}%\n  12~18時 #{per12to18}%\n  18~24時 #{per18to24}%\nいつでも聞いておくれ！"
            end

            #「明日」or「あした」というワードが含まれる場合
          when /.*(明後日|あさって).*/
            # info[2]:明日の天気
            per06to12 = doc.elements[xpath + 'info[3]/rainfallchance/period[2]'].text
            per12to18 = doc.elements[xpath + 'info[3]/rainfallchance/period[3]'].text
            per18to24 = doc.elements[xpath + 'info[3]/rainfallchance/period[4]'].text

            #降水確率50%以上か否か
            if per06to12.to_i >= rai_50per || per12to18.to_i >= rai_50per || per18to24.to_i >= rai_50per then
              push = "明後日は雨が降りそうだな。。\n降水確率はこうなっているぞ\n  6~12時 #{per06to12}%\n  12~18時 #{per12to18}%\n  18~24時 #{per18to24}%\nいつでも聞いておくれ！"
            else
              push = "明後日は雨は降らない予定だな！。\n降水確率はこうなっているぞ\n  6~12時 #{per06to12}%\n  12~18時 #{per12to18}%\n  18~24時 #{per18to24}%\nいつでも聞いておくれ！"
            end

          when /.*(かわいい|可愛い|カワイイ|きれい|綺麗|キレイ|素敵|ステキ|すてき|面白い|おもしろい|ありがと|すごい|スゴイ|スゴい|好き|頑張|がんば|ガンバ|たすか|助).*/
            push = "ありがとうな！\n良い1日を過ごせよ！"
          when /.*(バカ|馬鹿|ばか|クズ|くず|死|きえろ|役立たず|使えない|つかえない|外れ|はずれ|).*/
            push = "なんだと！\n傷つくからあんまり言わないで。。"
          else
            push = "すまん。わからんな。。"
          end

        #テキスト以外(画像等)のメッセージが送られた場合
       else
         push = "テキスト以外はわからんな〜"
       end

     message = {
       type: 'text'
       text: push
     }
     client.reply_message(event['replyToken'], message)

     #LINEお友達追加された場合(機能②)
     when Line::Bot::Event::Follow
       #登録したユーザーのidをユーザーテーブルに格納
       line_id = event['source']['userId']
       user.create(line_id: line_id)

     #お友達解除された場合(機能③)
     when Line::Bot::Event::Unfollow
       #お友達解除したユーザーのデータをユーザーテーブルから削除　
       line_id = event['source']['userId']
       User.find_by[line_id: line_id].destroy
     end
   }
   head: ok
 end

 private
 def client
   @client ||= Line::Bot::Client.new { |config|
     config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
     config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
   }
 end

end
