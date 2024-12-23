# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::AuthJobFinder, feature_category: :continuous_integration do
  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:job, reload: true) { create(:ci_build, status: :running, user: user) }

  let(:token) { job.token }

  subject(:finder) do
    described_class.new(token: token)
  end

  describe '#execute!' do
    subject(:execute) { finder.execute! }

    it { is_expected.to eq(job) }

    context 'with a database token' do
      before do
        stub_feature_flags(ci_job_token_jwt: false)
      end

      it { is_expected.to eq(job) }
    end

    it 'raises error if the job is not running' do
      job.success!

      expect { execute }.to raise_error described_class::NotRunningJobError, 'Job is not running'
    end

    it 'raises error if the job is erased' do
      expect(finder).to receive(:find_job_by_token).and_return(job)
      expect(job).to receive(:erased?).and_return(true)

      expect { execute }.to raise_error described_class::ErasedJobError, 'Job has been erased!'
    end

    it 'raises error if the the project is missing' do
      expect(finder).to receive(:find_job_by_token).and_return(job)
      expect(job).to receive(:project).and_return(nil)

      expect { execute }.to raise_error described_class::DeletedProjectError, 'Project has been deleted!'
    end

    it 'raises error if the the project is being removed' do
      project = double(Project)

      expect(finder).to receive(:find_job_by_token).and_return(job)
      expect(job).to receive(:project).twice.and_return(project)
      expect(project).to receive(:pending_delete?).and_return(true)

      expect { execute }.to raise_error described_class::DeletedProjectError, 'Project has been deleted!'
    end

    context 'with wrong job token' do
      let(:token) { 'missing' }

      it { is_expected.to be_nil }
    end
  end

  describe '#execute' do
    subject(:execute) { finder.execute }

    context 'when job is not running' do
      before do
        job.success!
      end

      it { is_expected.to be_nil }
    end

    context 'when job is running', :request_store do
      it 'sets ci_job_token_scope on the job user', :aggregate_failures do
        expect(subject).to eq(job)
        expect(subject.user).to be_from_ci_job_token
        expect(subject.user.ci_job_token_scope.current_project).to eq(job.project)
      end

      it 'logs context data about the job' do
        expect(::Gitlab::AppLogger).to receive(:info).with a_hash_including({
          job_id: job.id,
          job_user_id: job.user_id,
          job_project_id: job.project_id
        })

        execute
      end
    end
  end
end
