control 'flower' do
  impact 1.0
  title "Celery Flower UI"

  describe file('/etc/systemd/system/flower.service') do
    it { should be_owned_by 'root' }
    it { should exist  }
    it { should be_file }
  end

  describe service('flower') do
    it { should be_enabled }
    it { should be_running }
  end

end
