require 'twitter'
require 'mechanize'

CONSUMER_KEY = ""
CONSUMER_SECRET = ""
OAUTH_TOKEN = ""
OAUTH_TOKEN_SECRET = ""

NAME = ''
PASS = ''

@LOGIN_URL = 'https://tech.inf.in.shizuoka.ac.jp/labentry/index.php/stuentrylist'
@LABS_URL = 'https://tech.inf.in.shizuoka.ac.jp/labentry/index.php/labentrylist'

@agent = Mechanize.new
@agent.user_agent_alias = 'Linux Firefox'

def get_entries
  entries = Hash.new
  academician = Hash.new
  @agent.get(@LABS_URL) do |page|
    html = Nokogiri::HTML.parse(page.body)
    html.xpath('//tr').each_with_index do |node,i|
      if i != 0 && i!= 1 #exclude thead
        academician["定員"] = node.children[3].inner_text
        academician["CS"] = node.children[4].inner_text
        academician["IS"] = node.children[5].inner_text
        academician["ID"] = node.children[6].inner_text
        entries[node.children[0].inner_text] = academician
        academician = {}
      end
    end
  end
  return entries
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key = CONSUMER_KEY
  config.consumer_secret = CONSUMER_SECRET
  config.access_token = OAUTH_TOKEN
  config.access_token_secret = OAUTH_TOKEN_SECRET
end

@agent.get(@LOGIN_URL) do |page|
  @agent.page.form_with(:action => '/labentry/index.php/security/login') do |form|
    form.field_with(:name => 'login').value = NAME
    form.field_with(:name => 'password').value = PASS
  end.submit
end

before = get_entries
while true
  after = get_entries
  if before != after
    p("変更ありました")
    after.keys.each do |academician|  #get diff
      if after[academician] != before[academician]
        client.update("#{academician}\n"+
                      "定員:#{after[academician]["定員"]}\n"+
                      "CS:"+"#{before[academician]["CS"]}"+"=>"+"#{after[academician]["CS"]}\n"+
                      "IS:"+"#{before[academician]["IS"]}"+"=>"+"#{after[academician]["IS"]}\n"+
                      "ID:"+"#{before[academician]["ID"]}"+"=>"+"#{after[academician]["ID"]}"
        )
      end
    end
    before = after
  end
end


