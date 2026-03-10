# frozen_string_literal: true

module ChamomileTestHelpers
  def run_keys(model, *keys, width: 80, height: 24)
    harness = Chamomile::Testing::Harness.new(model, width: width, height: height)
    keys.each { |k| harness.send_key(k) }
    harness
  end
end

RSpec.configure do |config|
  config.include ChamomileTestHelpers
end
