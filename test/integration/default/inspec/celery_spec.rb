control 'Celery' do
  impact 1.0
  
  describe '' do
    it 'correct version is installed' do
      expect(command('celery --version').stdout).to include('4.1.0')
    end
  end

end
