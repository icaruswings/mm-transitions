require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "MongoMapper::Plugins::Transitions" do
  
  describe "New Record" do
    
    before(:each) do
      @light = TrafficLight.new
    end

    it "should set initial state" do
      @light.should be_off
      @light.current_state.should equal :off
    end

    it "should validate presence of state" do
      @light.should be_valid
      @light.state = nil
      @light.should_not be_valid
    end

  end
  
  describe "Saved Record" do
  
    before(:each) do
      @light = TrafficLight.create!
    end

    it "should set initial state" do
      @light.should be_off
      @light.current_state.should equal :off
    end

    it "should transition to a valid state" do
      @light.reset
      @light.should be_red
      @light.current_state.should equal :red

      @light.green_on
      @light.should be_green
      @light.current_state.should equal :green
    end

    it "should not persist state for event without !" do
      @light.reset
      @light.current_state.should equal :red 
      @light.reload
      @light.state.should eql "off"
    end

    it "should persist state for event with !" do
      @light.reset!
      @light.current_state.should equal :red 
      @light.reload
      @light.state.should eql "red"
    end

    it "should raise error on transition to invalid state" do
      lambda { @light.yellow_on }.should raise_error(Transitions::InvalidTransition)
      @light.current_state.should equal :off
    end

    it "should still persist state if state is protected" do
      protected_light = ProtectedTrafficLight.create!
      protected_light.reset!
      protected_light.current_state.should equal :red 
      protected_light.reload
      protected_light.state.should eql "red"
    end

    it "should not be valid without inclusive state" do
      for s in @light.class.state_machine.states
        @light.state = s.name
        @light.should be_valid
      end
      
      @light.state = "invalid_one"
      @light.should_not be_valid
    end

    it "should raise error on event! if model is invalid" do
      validating_light = ValidatingTrafficLight.create!(:name => 'Foobar')
      lambda { validating_light.reset! }.should raise_error(MongoMapper::DocumentNotValid)
    end

    it "should be able to use state? method in validation conditions" do
      validating_light = ConditionalValidatingTrafficLight.create!
      lambda { validating_light.reset! }.should raise_error(MongoMapper::DocumentNotValid)
      validating_light.should be_off
    end

    it "should reset current state on model reload" do
      @light.reset
      @light.should be_red
      @light.update_attribute(:state, 'green')
      @light.reload.should be_green, "reloaded state should come from database, not instance variable"
    end

  end
end