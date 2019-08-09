# archive_data_job.rb

module Boot

  class ArchiveDataJob

    def self.perform player_id, zone
      ArchiveData.try_archive player_id, zone
    end

  end

end
