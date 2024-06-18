# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPartitionIdCiPipelineMessage < BatchedMigrationJob
      operation_name :update_all
      feature_category :ci_scaling

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where('ci_pipeline_messages.pipeline_id = ci_pipelines.id')
            .update_all('partition_id = ci_pipelines.partition_id FROM ci_pipelines')
        end
      end
    end
  end
end
