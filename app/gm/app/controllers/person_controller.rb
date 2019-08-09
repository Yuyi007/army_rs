class PersonController < ApplicationController

  include RsRails

  layout 'main'

  protect_from_forgery

  before_filter :require_user

  access_control do
    allow :admin, :p0, :p1, :p2, :p3, :p4, :p5
  end

  PAGE_COUNT  =5

  def index
  end

  def view_base
    zone = params[:curZone].to_i
    uid = params[:uid]
    u_name = params[:name]
    p_id = params[:pid]
    logger.debug "view_base init: #{zone}, #{uid}, #{u_name}, #{p_id}."
    @persons = []
    if uid.to_s.strip == ""
      # logger.debug "view_base init11: #{zone}, #{uid}, #{u_name}, #{p_id}."
      if u_name.to_s.strip == ""
        # logger.debug "view_base init22: #{zone}, #{uid}, #{u_name}, #{p_id}."
        if p_id.to_s.strip == ""
          # logger.debug "view_base init33: #{zone}, #{uid}, #{u_name}, #{p_id}."
          return @persons
        else
          logger.debug "view_base init44: #{zone}, #{uid}, #{u_name}, #{p_id}."
          uid = YousiPlayerIdManager.get_player_id(p_id)
          logger.debug "view_base init55: #{zone}, #{uid}, #{u_name}, #{p_id}."
        end
      else
        ids = Player.search_by_name(u_name, zone)
        # logger.debug "view_base ids: #{ids}"
        ids.each do |pid|
          person = Person.find_one(pid)
          if person
            p = person_to_data(person)
            @persons << p
          end
        end
        return @persons
      end
    end
    if uid.nil? || uid.to_s.strip == ""
      # logger.debug "view_base init4455: #{zone}, #{uid}, #{u_name}, #{p_id}."
      return @persons
    end
    logger.debug "view_base init4466: #{zone}, #{uid}, #{u_name}, #{p_id}."
    1.upto(3) do|i|
      pid = "#{zone}_#{uid}_i#{i}"
      person = Person.find_one(pid)
      if person
        p = person_to_data(person)
        @persons << p
      end
    end
    @persons
  end

  def view_avatar
    pid = params[:pid]
    @person = Person.find_one(pid)
  end

  def view_unread_message_senders
    pid = params[:pid]
    p = Person.find_one(pid)
    @person = nil
    if p
      @person = {"pid" => p.pid}
      @person.unread_message_senders = p.unread_message_senders.to_a.to_data
    end
  end

  def view_followers
    pid = params[:pid]
    fs = []
    p = Person.find_one(pid)
    if p
      @person = {"pid" => p.pid}
      p.followers.each do|f|
        fs << person_to_data(f)
      end
    end

    @page = gen_page_data(params[:curPage].to_i, fs, PAGE_COUNT, {'page_url' => 'view_followers'})
  end

  def view_following
    pid = params[:pid]
    fs = []
    p = Person.find_one(pid)
    if p
      @person = {"pid" => p.pid}
      p.following.each do|f|
        fs << person_to_data(f)
      end
    end

    @page = gen_page_data(params[:curPage].to_i, fs, PAGE_COUNT, {'page_url' => 'view_following'})
  end

  def view_blocklist
    pid = params[:pid]
    fs = []
    p = Person.find_one(pid)
    if p
      @person = {"pid" => p.pid}
      p.blocklist.each do|f|
        fs << person_to_data(f)
      end
    end

    @page = gen_page_data(params[:curPage].to_i, fs, PAGE_COUNT, {'page_url' => 'view_blocklist'})
  end

  def view_followed
    pid = params[:pid]
    fs = []
    p = Person.find_one(pid)
    if p
      @person = {"pid" => p.pid}
      p.followed.each do|f|
        fs << person_to_data(f)
      end
    end

    @page = gen_page_data(params[:curPage].to_i, fs, PAGE_COUNT, {'page_url' => 'view_followed'})
  end

  def view_npcs
    pid = params[:pid]
    fs = []
    p = Person.find_one(pid)
    if p
      @person = {"pid" => p.pid}
      p.npcs.each do|f|
        fs << person_to_data(f)
      end
    end

    @page = gen_page_data(params[:curPage].to_i, fs, PAGE_COUNT, {'page_url' => 'view_npcs'})
  end

  def view_recent_contacts
    pid = params[:pid]
    fs = []
    p = Person.find_one(pid)
    if p
      @person = {"pid" => p.pid}
      p.recent_contacts.each do|f|
        fs << person_to_data(f)
      end
    end

    @page = gen_page_data(params[:curPage].to_i, fs, PAGE_COUNT, {'page_url' => 'view_recent_contacts', 'sort' => 'contact_time'})
  end

  def view_timeline
    pid = params[:pid]
    ts = []
    p = Person.find_one(pid)
    if p
      @person = {"pid" => p.pid}
      p.timeline.each do|f|
        ts << tweet_to_data(f)
      end
    end

    @page = gen_tweet_page_data(params[:curPage].to_i, ts, PAGE_COUNT, {'page_url' => 'view_timeline'})
  end

  def view_tweets
    pid = params[:pid]
    ts = []
    p = Person.find_one(pid)
    if p
      @person = {"pid" => p.pid}
      p.tweets.each do|f|
        ts << tweet_to_data(f)
      end
    end

    @page = gen_tweet_page_data(params[:curPage].to_i, ts, PAGE_COUNT, {'page_url' => 'view_tweets'})
  end

  def view_news_tweets
    pid = params[:pid]
    ts = []
    p = Person.find_one(pid)
    if p
      @person = {"pid" => p.pid}
      p.news_tweets.each do|f|
        ts << tweet_to_data(f)
      end
    end

    @page = gen_tweet_page_data(params[:curPage].to_i, ts, PAGE_COUNT, {'page_url' => 'view_news_tweets'})
  end

  def view_tweet_bonus
    pid = params[:pid]
    id = params[:id]
    t = find_tweet(pid, id)
    @bonus = nil
    if t
      @person = {"pid" => pid}
      @bonus = t.bonus.to_data
    end
  end

  def view_tweet_bonus_commenters
    pid = params[:pid]
    id = params[:id]
    t = find_tweet(pid, id)
    fs = []
    if t
      @person = {"pid" => pid}
      @tweet = {"id" => t.id, "pid" => t.pid}
      t.bonus_commenters.each do|f|
        fs << person_to_data(f)
      end
    end
    @page = gen_page_data(params[:curPage].to_i, fs, PAGE_COUNT, {'page_url' => 'view_tweet_bonus_commenters'})
  end

  def view_tweet_bonus_liked
    pid = params[:pid]
    id = params[:id]
    t = find_tweet(pid, id)
    fs = []
    if t
      @person = {"pid" => pid}
      @tweet = {"id" => t.id, "pid" => t.pid}
      t.bonus_liked.each do|f|
        fs << person_to_data(f)
      end
    end
    @page = gen_page_data(params[:curPage].to_i, fs, PAGE_COUNT, {'page_url' => 'view_tweet_bonus_liked'})
  end

  def view_tweet_comments
    pid = params[:pid]
    id = params[:id]
    t = find_tweet(pid, id)
    cs = []
    if t
      @person = {"pid" => pid}
      @tweet = {"id" => t.id, "pid" => t.pid}
      t.comments.each do|c|
        cs << comment_to_data(c)
      end
    end
    @page = gen_comment_page_data(params[:curPage].to_i, cs, PAGE_COUNT, {'page_url' => 'view_tweet_comments'})
  end

  def find_tweet(pid, tweet_id)
    tweet = nil
    ts = Tweet.find(pid: pid)
    ts.each do|t|
      if t.id == tweet_id
        tweet = t
        break
      end
    end
    tweet
  end

  def gen_page_data(pagei, person_list, per_page_count, options = {})
    cur_page = 1
    page_url = options.page_url or 'view_followers'
    sort = options.sort or 'id'
    if !pagei.nil?
      cur_page = pagei.to_i
    end
    start_idx = (cur_page - 1) * per_page_count
    end_idx = cur_page * per_page_count - 1
    persons = []
    if person_list[start_idx]
      start_idx.upto(end_idx) do|i|
        persons << person_list[i] if person_list[i]
      end
    end
    args = {"dataSource" => persons,
      "pageNum" => ((person_list.length/per_page_count.to_f).to_f).ceil,
      "sort" => sort,
      "direction" => 'DESC',
      "dataType" => 'table',
      "perPage" => per_page_count,
      "curPage" => cur_page,
      "pageUrl" => page_url}
    PageGen.genPage(args)
  end

  def gen_tweet_page_data(pagei, tweet_list, per_page_count, options = {})
    cur_page = 1
    page_url = options.page_url or 'view_timeline'
    sort = options.sort or 'time'
    if !pagei.nil?
      cur_page = pagei.to_i
    end
    start_idx = (cur_page - 1) * per_page_count
    end_idx = cur_page * per_page_count - 1
    tweets = []
    if tweet_list[start_idx]
      start_idx.upto(end_idx) do|i|
        tweets << tweet_list[i] if tweet_list[i]
      end
    end
    args = {"dataSource" => tweets,
      "pageNum" => ((tweet_list.length/per_page_count.to_f).to_f).ceil,
      "sort" => sort,
      "direction" => 'DESC',
      "dataType" => 'table',
      "perPage" => per_page_count,
      "curPage" => cur_page,
      "pageUrl" => page_url}
    PageGen.genPage(args)
  end

  def gen_comment_page_data(pagei, comment, per_page_count, options = {})
    cur_page = 1
    page_url = options.page_url or 'view_tweet_comments'
    sort = options.sort or 'id'
    if !pagei.nil?
      cur_page = pagei.to_i
    end
    start_idx = (cur_page - 1) * per_page_count
    end_idx = cur_page * per_page_count - 1
    comments = []
    if comment[start_idx]
      start_idx.upto(end_idx) do|i|
        comments << comment[i] if comment[i]
      end
    end
    args = {"dataSource" => comments,
      "pageNum" => ((comment.length/per_page_count.to_f).to_f).ceil,
      "sort" => sort,
      "direction" => 'DESC',
      "dataType" => 'table',
      "perPage" => per_page_count,
      "curPage" => cur_page,
      "pageUrl" => page_url}
    PageGen.genPage(args)
  end

  def person_to_data(person)
    p = person.to_data
    if p.faction && GameConfig.roledes[p.faction]
      p.faction_name = GameConfig.roledes[p.faction].name
    else
      p.faction_name = ''
    end
    p
  end

  def tweet_to_data(tweet)
    tweet.to_data
  end

  def comment_to_data(comment)
    comment.to_data
  end

end