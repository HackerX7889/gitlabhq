class Compare
  include Gitlab::Utils::StrongMemoize

  delegate :same, :head, :base, to: :@compare

  attr_reader :project

  def self.decorate(compare, project)
    if compare.is_a?(Compare)
      compare
    else
      self.new(compare, project)
    end
  end

  def initialize(compare, project, base_sha: nil, straight: false)
    @compare = compare
    @project = project
    @base_sha = base_sha
    @straight = straight
  end

  def commits
    @commits ||= Commit.decorate(@compare.commits, project)
  end

  # def start_commit
  #   strong_memoize(:start_commit) do
  #     commit = @compare.base
  #
  #     ::Commit.new(commit, project) if commit
  #   end
  # end

  # def head_commit
  #   strong_memoize(:head_commit) do
  #     commit = @compare.head
  #
  #     ::Commit.new(commit, project) if commit
  #   end
  # end
  # alias_method :commit, :head_commit

  def start_commit_sha
    @compare.base
  end

  def base_commit_sha
    strong_memoize(:base_commit) do
      next unless start_commit_sha && head_commit_sha

      @base_sha || project.merge_base_commit(start_commit_sha, head_commit_sha)&.sha
    end
  end

  def head_commit_sha
    @compare.head
  end

  def raw_diffs(*args)
    @compare.diffs(*args)
  end

  def diffs(diff_options = nil)
    Gitlab::Diff::FileCollection::Compare.new(self,
      project: project,
      diff_options: diff_options,
      diff_refs: diff_refs)
  end

  def diff_refs
    Gitlab::Diff::DiffRefs.new(
      base_sha:  @straight ? start_commit_sha : base_commit_sha,
      start_sha: start_commit_sha,
      head_sha: head_commit_sha
    )
  end
end
