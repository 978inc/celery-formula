control 'celeryd' do
  impact 1.0
  title "Celery worker daemon"

  describe file('/etc/default/celeryd') do
    it { should be_owned_by 'celery' }
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

control "celery-defaults" do
  impact 1.0
  title "Celery configuration defaults"


  describe file('/var/log/celery/') do
    it {should be_directory }
    it { should exist }
  end

  describe file('/usr/local/bin/celery') do
    it {should be_file }
    it {should be_executable}
  end

  describe file('/var/log/celery/celeryd-celeryd.service.log') do
    it {should be_file }
    it { should be_owned_by "celery" }
  end

  describe file('/tmp/celery/working/celeryd.py') do
    it { should be_file }
    it { should be_owned_by "celery"}
    it { should_not be_executable }
  end

  describe file('/etc/systemd/system/celeryd.service') do
    it { should be_file }
    it { should be_owned_by "celery"}
  end
end

control 'celery-config' do
  impact 1.0
  title 'Generated worker configuration content'

  describe parse_config_file('/etc/default/celeryd', { multiple_values: true}) do
    its('CELERY_CONFIG_MODULE') { should eq ["\"celeryd\""] }
    its('CELERYD_PID_FILE') { should eq ['"/var/run/celery/celeryd-%n.pid"'] }
    its('CELERYD_STATE_FILE') { should eq ['"/var/run/celery/celeryd/%n.state"'] }
    its('CELERYD_CHDIR') { should eq ['"/tmp/celery/working"'] }
    its('CELERYD_CREATE_DIRS') { should eq ["1"]}
    its('CELERYD_LOG_LEVEL') { should eq ["\"DEBUG\""] }
    its('CELERYD_LOG_FILE') { should eq ['"/var/log/celery/celeryd-%n%I.log"'] }
    its('CELERYD_MULTI') { should eq ['"multi"']}
    its('CELERYD_NODES') { should eq ['"superfast notfast"']}
    its('CELERYD_OPTS') { should eq ['"-c:2 10"']}
    its('CELERY_BIN') { should eq ['"/usr/local/bin/celery"']}
  end

  
end
