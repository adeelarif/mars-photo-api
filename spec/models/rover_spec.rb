require 'rails_helper'

RSpec.describe Rover, type: :model do
  let(:photo) { create(:photo) }

  describe ".max_sol" do
    it "should return the highest sol for the Rover's photos" do
      expect(photo.rover.max_sol).to eq 829
    end
  end

  describe ".max_date" do
    it "should return the highest date for the Rover's photos" do
      expect(photo.rover.max_date).to eq Date.new(2014, 12, 5)
    end
  end
end
