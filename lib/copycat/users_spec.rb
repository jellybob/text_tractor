require 'spec_helper'

describe Copycat::Users do
  it { should_not be_nil }

  specify { Copycat::Users.should respond_to(:all) }
  specify { Copycat::Users.should respond_to(:authenticate) }
  specify { Copycat::Users.should respond_to(:create) }
  specify { Copycat::Users.should respond_to(:get) }
end
