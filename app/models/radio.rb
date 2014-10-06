class Radio < ActiveRecord::Base
  after_create :boot_radio

  def boot_radio
    RadioBooter.perform_async self.id
  end

  def container
    Docker::Container.get self.docker_container_id
  end
end