class SinatraApp2 < Sinatra::Base
  get('/') { raise AirbrakeTestError }
end

Airbrake.configure(SinatraApp2) do |c|
  c.project_id = 113743
  c.project_key = 'fd04e13d806a90f96614ad8e529b2822'
  c.logger = Logger.new('/dev/null')
end
