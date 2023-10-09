require 'rails_helper'

RSpec.describe SubmittableValidator do
  before do
    stub_const('Validatable', Class.new).class_eval do
      include ActiveModel::Validations
      attr_accessor :postcode
      validates :postcode, postcode: true
    end
  end

end
