# frozen_string_literal: true

# Mixin for resolving merge requests. All arguments must be in forms
# that `MergeRequestsFinder` can handle, so you may need to use aliasing.
module ResolvesMergeRequests
  extend ActiveSupport::Concern
  include ::Gitlab::Utils::StrongMemoize
  include LooksAhead

  NON_STABLE_CURSOR_SORTS = %i[priority_asc priority_desc
    popularity_asc popularity_desc
    label_priority_asc label_priority_desc
    milestone_due_asc milestone_due_desc].freeze

  included do
    type Types::MergeRequestType, null: true
  end

  def resolve_with_lookahead(**args)
    if args[:group_id]
      args[:group_id] = ::GitlabSchema.parse_gid(args[:group_id], expected_type: ::Group).model_id
      args[:include_subgroups] = true
    end

    args.delete(:subscribed) if Feature.disabled?(:filter_subscriptions, current_user)
    rewrite_param_name(args, :reviewer_wildcard_id, :reviewer_id)
    rewrite_param_name(args, :assignee_wildcard_id, :assignee_id)

    mr_finder = MergeRequestsFinder.new(current_user, prepare_finder_params(args.compact))
    finder = Gitlab::Graphql::Loaders::IssuableLoader.new(mr_parent, mr_finder)

    merge_requests = select_result(finder.batching_find_all { |query| apply_lookahead(query) })

    if non_stable_cursor_sort?(args[:sort])
      # Certain complex sorts are not supported by the stable cursor pagination yet.
      # In these cases, we use offset pagination, so we return the correct connection.
      offset_pagination(merge_requests)
    else
      merge_requests
    end
  end

  def ready?(**args)
    return early_return if no_results_possible?(args)

    super
  end

  def early_return
    [false, single? ? nil : MergeRequest.none]
  end

  private

  def prepare_finder_params(args)
    args
  end

  def mr_parent
    project
  end

  def unconditional_includes
    [:target_project, :author]
  end

  def rewrite_param_name(params, old_name, new_name)
    params[new_name] = params.delete(old_name) if params && params[old_name].present?
  end

  def preloads
    {
      assignees: [:assignees],
      award_emoji: { award_emoji: [:awardable] },
      reviewers: [:reviewers],
      participants: MergeRequest.participant_includes,
      author: [:author],
      merged_at: [:metrics],
      closed_at: [:metrics],
      commit_count: [:metrics],
      diff_stats_summary: [:metrics],
      approved_by: [:approved_by_users],
      merge_after: [:merge_schedule],
      mergeable: [:merge_schedule],
      detailed_merge_status: [:merge_schedule],
      milestone: [:milestone],
      security_auto_fix: [:author],
      head_pipeline: [:merge_request_diff, { head_pipeline: [:merge_request, :project] }],
      timelogs: [:timelogs],
      pipelines: [:merge_request_diffs], # used by `recent_diff_head_shas` to load pipelines
      committers: [merge_request_diff: [:merge_request_diff_commits]],
      suggested_reviewers: [:predictions],
      diff_stats: [latest_merge_request_diff: [:merge_request_diff_commits]],
      source_branch_exists: [:source_project, { source_project: [:route] }]
    }
  end

  def non_stable_cursor_sort?(sort)
    NON_STABLE_CURSOR_SORTS.include?(sort)
  end

  def resource_parent
    # The project could have been loaded in batch by `BatchLoader`.
    # At this point we need the `id` of the project to query for issues, so
    # make sure it's loaded and not `nil` before continuing.
    object.respond_to?(:sync) ? object.sync : object
  end
  strong_memoize_attr :resource_parent
end

ResolvesMergeRequests.prepend_mod
