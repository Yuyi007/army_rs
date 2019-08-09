class GetNoticeList < Handler
  def self.process(session, msg)
    res = { 'success' => false }
    notices = GameEventsDb.get_notice_configs
    res['notices'] = []
    res['notices'][0] = []
    res['notices'][1] = []
    notices = notices.sort{ |x, y|
      y.tid <=> x.tid
    }
    notices.each { |notice|
      res['notices'][notice.type - 1] << notice
    }
    res.success = true
    res
  end
end