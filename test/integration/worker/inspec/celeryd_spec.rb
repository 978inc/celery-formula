control 'celeryd' do
  impact 1.0
  title "Celery worker daemon"

  describe file('/etc/default/celeryd') do
    it { should be_owned_by 'root' }
    it { should exist  }
    it { should be_file }
  end

  describe service('celeryd') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/tmp/celery/working/celeryd.py') do
    it { should be_owned_by 'celery' }
    it { should exist  }
    it { should be_file }
  end
end
