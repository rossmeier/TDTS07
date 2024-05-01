#include "generator.h"
#include "controller.h"
#include <cstdlib>
#include <sysc/kernel/sc_simcontext.h>
#include <sysc/kernel/sc_time.h>

Generator::Generator(sc_module_name name, double pressure)
    : sc_module(name), pressure{pressure} {
  SC_THREAD(handle);
}

void Generator::handle() {
  for (;;) {
    double result = static_cast<double>(rand()) / RAND_MAX;
    int queue = queue_length.read();
    if (!queue) {
      // empty queue
      if (result < pressure) {
        queue = 1;
      }
    } else {
      if (result > static_cast<double>(queue) / pressure) {
        queue++;
      }
    }
    queue_length->write(queue);
    sensor->write(!!queue);
    wait(sc_time(100, SC_MS));
    if (light.read() == LightColor::Green && queue) {
      queue--;
    }
    queue_length->write(queue);
    sensor->write(!!queue);
    wait(sc_time(1, SC_SEC));
  }
}
