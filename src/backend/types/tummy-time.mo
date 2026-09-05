module {
  public type TummyTimeSession = {
    sessionId : Text;
    childId : Text;
    startTime : Int;
    duration : Int;
  };

  public type TummyTimeTimerState = {
    childId : Text;
    userId : Principal;
    startTime : Int;
    isPaused : Bool;
    pausedAt : ?Int;
    totalPausedDuration : Int;
  };
};
