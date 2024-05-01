#ifndef CONTROLLER_H
#define CONTROLLER_H

#include <optional>
#include <sysc/kernel/sc_event.h>
#include <sysc/kernel/sc_time.h>
#include <systemc.h>

// max time till switch if cars are waiting on blocking side
// higher value -> more throughput
// lower value -> more delay
// ideally should be dynamically adjusted based on demand
const auto max_wait_time = sc_time(10, SC_SEC);

enum Direction {
  N = 0,
  S = 1,
  W = 2,
  E = 3,
  MAX,
};

enum LightColor {
  Red = 0,
  // Yellow, (would be nice to have in the future, but may be too complicated)
  Green = 1,
};

enum State {
  Idle = 0,
  NorthSouth = 1,
  WestEast = 2,
};

SC_MODULE(Controller) {
  // The controller only sees if there are cars waiting, testbench should
  // manage number of cars
  sc_in<bool> sensor_N;
  sc_in<bool> sensor_S;
  sc_in<bool> sensor_W;
  sc_in<bool> sensor_E;
  // lights pointing in the respective directions, also affecting the respective
  // cars
  sc_out<int> light_N;
  sc_out<int> light_S;
  sc_out<int> light_W;
  sc_out<int> light_E;
  // current state of the controller
  State state;
  // if cars coming from blocked direction, set this to current_time +
  // max_wait_time
  bool state_change_scheduled;
  sc_out<int> state_out;
  sc_event state_change;

  SC_HAS_PROCESS(Controller);
  Controller(sc_module_name name);

  void schedule_state_change(std::optional<sc_time> relative_time);
  void handle();
};

#endif // GENERATOR_H
