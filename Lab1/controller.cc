#include "controller.h"
#include <algorithm>
#include <array>
#include <functional>
#include <optional>
#include <sysc/communication/sc_signal_ports.h>
#include <sysc/kernel/sc_simcontext.h>

Direction opposite(Direction dir) {
  switch (dir) {
  case N:
    return Direction::S;
  case S:
    return Direction::N;
  case W:
    return Direction::E;
  case E:
    return Direction::W;
  }
}

State opposite(State state) {
  switch (state) {
  case State::NorthSouth:
    return State::WestEast;
  case State::WestEast:
    return State::NorthSouth;
  }
}

const State required_state[Direction::MAX] = {
    State::NorthSouth, // N
    State::NorthSouth, // S
    State::WestEast,   // W
    State::WestEast,   // E
};

Controller::Controller(sc_module_name name)
    : sc_module(name), state(State::Idle), state_change_scheduled(false) {
  light_E.initialize(LightColor::Red);
  light_N.initialize(LightColor::Red);
  light_S.initialize(LightColor::Red);
  light_W.initialize(LightColor::Red);
  state_out.initialize(State::Idle);

  SC_METHOD(handle);
  dont_initialize();
  sensitive << sensor_E << sensor_N << sensor_W << sensor_S << state_change;
}

void Controller::handle() {
  std::array<bool, Direction::MAX> sensors = {
      sensor_N->read(),
      sensor_S->read(),
      sensor_W->read(),
      sensor_E->read(),
  };
  std::array<LightColor, Direction::MAX> lights = {
      static_cast<LightColor>(light_N->read()),
      static_cast<LightColor>(light_S->read()),
      static_cast<LightColor>(light_W->read()),
      static_cast<LightColor>(light_E->read()),
  };
  // force state change
  if (state_change.triggered()) {
    for (auto &light : lights) {
      light = LightColor::Red;
    }
    state = opposite(state);
    state_out.write(static_cast<int>(state));
    state_change_scheduled = false;
  }
  bool runAgain = false;
  do {
    runAgain = false;
    // C-style loop :/
    for (int i = 0; i < static_cast<int>(Direction::MAX); i++) {
      const Direction dir = static_cast<Direction>(i);
      if (!sensors[dir] && lights[dir] == LightColor::Green) {
        lights[dir] = LightColor::Red;
      }
      if (sensors[dir] && lights[dir] == LightColor::Red) {
        if (state == required_state[dir]) {
          lights[dir] = LightColor::Green;
        } else if (state == State::Idle) {
          lights[dir] = LightColor::Green;
          state = required_state[dir];
          state_out.write(static_cast<int>(state));
        } else {
          schedule_state_change(max_wait_time);
        }
      }
    }
    if (std::all_of(lights.begin(), lights.end(),
                    [](auto light) { return light == LightColor::Red; })) {
      if (state_change_scheduled) {
        // cars are waiting on other state
        schedule_state_change(std::nullopt);
        state = opposite(state);
        state_out.write(static_cast<int>(state));
        // state has changed, re-evaluate everything
        runAgain = true;
        break;
      } else {
        // no cars waiting, go idle
        state = State::Idle;
        state_out.write(static_cast<int>(state));
        break;
      }
    }
  } while (runAgain);
  light_N.write(lights[Direction::N]);
  light_S.write(lights[Direction::S]);
  light_W.write(lights[Direction::W]);
  light_E.write(lights[Direction::E]);
}

void Controller::schedule_state_change(std::optional<sc_time> relative_time) {
  if (!relative_time.has_value()) {
    state_change_scheduled = false;
    state_change.cancel();
  } else if (state_change_scheduled) {
    // state change already scheduled, ignore
  } else {
    state_change_scheduled = true;
    state_change.notify(*relative_time);
  }
}