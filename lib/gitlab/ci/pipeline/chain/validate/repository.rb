# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class Repository < Chain::Base
            include Chain::Helpers

            def perform!
              unless @command.branch_exists? || @command.tag_exists?
                return error('Reference not found')
              end

              unless @command.sha
                return error('Commit not found')
              end

              unless @command.project.resolve_ref(@command.origin_ref)
                return error('Ref is ambiguous')
              end
            end

            def break?
              @pipeline.errors.any?
            end
          end
        end
      end
    end
  end
end
