require 'spec_helper'

describe TextTractor::Users do
  it { should_not be_nil }

  specify { TextTractor::Users.should respond_to(:all) }
  specify { TextTractor::Users.should respond_to(:authenticate) }
  specify { TextTractor::Users.should respond_to(:create) }
  specify { TextTractor::Users.should respond_to(:get) }
end
