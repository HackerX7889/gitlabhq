# frozen_string_literal: true
module Ci
  class AuthJobFinder
    AuthError = Class.new(StandardError)
    NotRunningJobError = Class.new(AuthError)
    ErasedJobError = Class.new(AuthError)
    DeletedProjectError = Class.new(AuthError)

    def initialize(token:)
      @token = token
    end

    def execute!
      find_job_by_token.tap do |job|
        next unless job

        validate_job!(job)

        job.user.set_ci_job_token_scope!(job) if job.user
      end
    end

    def execute
      execute!
    rescue AuthError
    end

    private

    attr_reader :token

    def find_job_by_token
      job_token = ::Ci::JobToken::Jwt::Decode.new(token)
      job_token.jwt? ? job_token.job : ::Ci::Build.find_by_token(token)
    end

    def validate_job!(job)
      validate_running_job!(job)
      validate_job_not_erased!(job)
      validate_project_presence!(job)

      log_successful_job_auth(job)

      true
    end

    def validate_running_job!(job)
      raise NotRunningJobError, 'Job is not running' unless job.running?
    end

    def validate_job_not_erased!(job)
      raise ErasedJobError, 'Job has been erased!' if job.erased?
    end

    def validate_project_presence!(job)
      raise DeletedProjectError, 'Project has been deleted!' if job.project.nil? || job.project.pending_delete?
    end

    def log_successful_job_auth(job)
      Gitlab::AppLogger.info({
        class: self.class,
        job_id: job.id,
        job_user_id: job.user_id,
        job_project_id: job.project_id,
        message: "successful job token auth"
      }.merge(Gitlab::ApplicationContext.current))
    end
  end
end
