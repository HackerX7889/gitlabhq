# frozen_string_literal: true

class FinalizeBackfillRelatedEpicLinksToIssueLinks < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillRelatedEpicLinksToIssueLinks',
      table_name: :related_epic_links,
      column_name: 'id',
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # No op
  end
end
