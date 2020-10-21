require 'rails_helper'
require 'clockwork/test'
require 'sidekiq'

RSpec.describe Clockwork do
  around do |example|
    Sidekiq::Testing.inline! do
      timecop_safe_mode = Timecop.safe_mode?
      Timecop.safe_mode = false # cannot pass a timecop block to clockwork/test
      example.run
      Timecop.safe_mode = timecop_safe_mode
    end
  end

  describe 'SendApplicationsToProviderWorker schedule' do
    before do
      @service = instance_double(SendApplicationsToProvider, call: true)
      allow(@service).to receive(:call).and_return(true)
      allow(SendApplicationsToProvider).to receive(:new).and_return(@service)
    end

    it 'runs the job every hour' do
      start_time = Time.zone.local(2019, 11, 7, 0, 4, 0)
      end_time = Time.zone.local(2019, 11, 7, 1, 6, 0)
      Clockwork::Test.run(
        start_time: start_time,
        end_time: end_time,
        tick_speed: 1.minute,
        file: './config/clock.rb',
      )
      expect(Clockwork::Test.times_run('SendApplicationsToProvider')).to eq 2
    end

    it 'queues a SendApplicationsToProvider worker' do
      start_time = Time.zone.local(2019, 11, 7, 0, 4, 0)
      end_time = Time.zone.local(2019, 11, 7, 1, 6, 0)
      Clockwork::Test.run(
        start_time: start_time,
        end_time: end_time,
        tick_speed: 1.minute,
        file: './config/clock.rb',
      )
      Clockwork::Test.block_for('SendApplicationsToProvider').call
      expect(@service).to have_received(:call)
    end
  end

  [
    { worker: DeclineOffersByDefaultWorker, task: 'DeclineOffersByDefault' },
    { worker: SendChaseEmailToProvidersWorker, task: 'SendChaseEmailToProviders' },
    { worker: SendChaseEmailToCandidatesWorker, task: 'SendChaseEmailToCandidates' },
  ].each do |worker|
    describe 'worker schedule' do
      it 'runs the job every hour' do
        start_time = Time.zone.local(2020, 1, 2, 0, 0, 0)
        end_time = Time.zone.local(2020, 1, 2, 3, 0, 0)
        Clockwork::Test.run(
          start_time: start_time,
          end_time: end_time,
          tick_speed: 1.minute,
          file: './config/clock.rb',
        )
        expect(Clockwork::Test.times_run(worker[:task])).to eq 3
      end

      it 'queues a worker task' do
        allow(worker[:worker]).to receive(:perform_async)
        Clockwork::Test.run(max_ticks: 60, tick_speed: 1.minute, file: './config/clock.rb')
        Clockwork::Test.block_for(worker[:task]).call
        expect(worker[:worker]).to have_received(:perform_async)
      end
    end
  end
end
