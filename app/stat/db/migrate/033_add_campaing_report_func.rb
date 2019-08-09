class AddCampaingReportFunc < ActiveRecord::Migration
	def change
		func = {:name => 'campaign_report', :desc => 'Lookup all campaign start or finish report' }
		SiteUsers::SysFunctions.create :name => func[:name], :desc => func[:desc]
	end
end
