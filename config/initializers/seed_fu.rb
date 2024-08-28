# frozen_string_literal: true

SeedFu.fixture_paths += %W[ee/db/fixtures ee/db/fixtures/#{Rails.env}] if Gitlab.ee?

require 'benchmark'

seed_timer = Module.new do
  def run
    duration = Benchmark.realtime { super }

    printf "== Seeding took %.2f seconds\n", duration
  end

  private

  def run_file(filename)
    duration = Benchmark.realtime { super }

    printf "== %s took %.2f seconds\n", filename, duration
  end
end

SeedFu::Runner.prepend seed_timer
