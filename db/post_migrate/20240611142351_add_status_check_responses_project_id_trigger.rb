# frozen_string_literal: true

class AddStatusCheckResponsesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :status_check_responses,
      sharding_key: :project_id,
      parent_table: :merge_requests,
      parent_sharding_key: :target_project_id,
      foreign_key: :merge_request_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :status_check_responses,
      sharding_key: :project_id,
      parent_table: :merge_requests,
      parent_sharding_key: :target_project_id,
      foreign_key: :merge_request_id
    )
  end
end
