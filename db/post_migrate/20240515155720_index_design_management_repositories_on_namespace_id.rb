# frozen_string_literal: true

class IndexDesignManagementRepositoriesOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_design_management_repositories_on_namespace_id'

  def up
    add_concurrent_index :design_management_repositories, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :design_management_repositories, INDEX_NAME
  end
end
