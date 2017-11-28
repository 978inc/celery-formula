control 'Celery' do
  impact 1.0
  
  describe '' do
    it 'correct version is installed' do
      expect(command('celery --version').stdout).to include('4.1.0')
    end
  end

  describe file('/var/log/celery') do
    it { should be_directory }
    it { should be_owned_by 'celery' }
    it { should be_grouped_into 'celery' }
  end

  describe file('/var/log/celery') do
    it { should be_directory }
    it { should be_owned_by 'celery' }
    it { should be_grouped_into 'celery' }
  end

end
