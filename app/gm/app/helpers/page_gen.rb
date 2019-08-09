class PageGen

	def self.genPage pageInfo
		page = {}
		dataSource = pageInfo['dataSource']
	    sort = pageInfo['sort']
	    direction = pageInfo['direction']
	    dataType = pageInfo['dataType']
	    if dataType == 'table'
	    	if direction == 'ASC'
	    		dataSource.sort!{|v1,v2| v1[sort] <=> v2[sort]}
	    	else
	    		dataSource.sort!{|v1,v2| v2[sort] <=> v1[sort]}
	    	end
	    elsif dataType == 'model'
	    	if direction == 'ASC'
	    		dataSource.sort!{|v1,v2| v1.send(sort) <=> v2.send(sort)}
	    	else
	    		dataSource.sort!{|v1,v2| v2.send(sort) <=> v1.send(sort)}
	    	end
	    end

		page.perPage = pageInfo['perPage']
    page.pageNum = pageInfo.pageNum || ((dataSource.length.to_f/page.perPage.to_f).to_f).ceil
    page.pages = Array.new(page.pageNum){|i| (i+1).to_i}
    page.curPage = pageInfo['curPage'] || 1
    page.pageUrl = pageInfo['pageUrl']
    if page.curPage <= 0
    	page.curPage = 1
    end
    page.data = dataSource[0..-1]
    page
	end
end