# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::VirtualRegistries::Packages::Maven::CachedResponse, feature_category: :virtual_registry do
  let(:cached_response) { build_stubbed(:virtual_registries_packages_maven_cached_response) }

  subject { described_class.new(cached_response).as_json }

  it do
    is_expected.to include(:cached_response_id, :group_id, :upstream_id, :upstream_checked_at, :created_at, :updated_at,
      :file, :size, :downloaded_at, :downloads_count, :relative_path, :upstream_etag, :content_type)
  end
end
