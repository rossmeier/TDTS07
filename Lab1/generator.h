#ifndef GENERATOR_H
#define GENERATOR_H

#include "controller.h"
#include <optional>
#include <sysc/kernel/sc_event.h>
#include <sysc/kernel/sc_time.h>
#include <systemc.h>

SC_MODULE(Generator) {
  sc_out<bool> sensor;
  sc_out<int> queue_length;
  sc_in<int> light;
  double pressure;

  SC_HAS_PROCESS(Generator);
  Generator(sc_module_name name, double pressure);

  void handle();
};

#endif // GENERATOR_H
