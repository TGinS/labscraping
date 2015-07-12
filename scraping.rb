require 'twitter'
require 'mechanize'

CONSUMER_KEY = "LnTrHw1DoSIF9Le0QfXJkpA4a"
CONSUMER_SECRET = "PSzkOgqsozypFMaVI7UkDiJpI45i1nTAwAPgf0eZH3IRCDUJ8j"
OAUTH_TOKEN = "3277253898-N5YjOWRa5MKsg7bfzkG7QcCQjVPm7HHtFB9m4IE"
OAUTH_TOKEN_SECRET = "i7896z0kRWSeuKxZkJw6mduo0EavJTWYnNiNzlCLu2MA5"

NAME = 'ia13023'
PASS = 'twttk-admin-5509'

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
                      "CS:#{after[academician]["CS"]}\n"+
                      "IS:#{after[academician]["IS"]}\n"+
                      "ID:#{after[academician]["ID"]}\n")
        p academician
        p ("定員:" + after[academician]["定員"])
        p ("CS:" + before[academician]["CS"] + "=>" + after[academician]["CS"])
        p ("IS:" + before[academician]["IS"] + "=>" + after[academician]["IS"])
        p ("ID:" + before[academician]["ID"] + "=>" + after[academician]["ID"])
      end
    end
    before = after
  end
  p ("--------before------------")
  p before
  p ("--------after-------------")
  p after
  sleep(10)
  p ("--------next--------------")
end


