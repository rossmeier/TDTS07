#include "controller.h"
#include "generator.h"
#include <array>
#include <sysc/kernel/sc_simcontext.h>
#include <systemc.h>

int sc_main(int argc, char **argv) {
  // The command-line arguments are as follows:
  // 1. the simulation time (in seconds),
  // 2. the file with input data (see input.txt), and
  // 3. the file to write output data.
  assert(argc == 2);
  // not implemented?
  // sc_set_random_seed(1337);
  srand(1337);

  sc_trace_file *file = sc_create_vcd_trace_file("trace");
  // sc_trace(file, s, "signal");

  sc_time sim_time(atof(argv[1]), SC_SEC);
  // char *outfile = argv[3];

  // Create channels.
  sc_signal<int> numerator_sig;
  sc_signal<int> denominator_sig;
  sc_signal<double> quotient_sig;

  std::array<sc_signal<bool>, Direction::MAX> sensors = {};
  std::array<sc_signal<int>, Direction::MAX> lights = {};
  std::array<sc_signal<int>, Direction::MAX> queue_lengths = {};
  sc_trace(file, queue_lengths[Direction::N], "queue_lengthN");
  sc_trace(file, queue_lengths[Direction::S], "queue_lengthS");
  sc_trace(file, queue_lengths[Direction::E], "queue_lengthE");
  sc_trace(file, queue_lengths[Direction::W], "queue_lengthW");
  sc_trace(file, lights[Direction::N], "lightN");
  sc_trace(file, lights[Direction::S], "lightS");
  sc_trace(file, lights[Direction::E], "lightE");
  sc_trace(file, lights[Direction::W], "lightW");
  sc_trace(file, sensors[Direction::N], "sensorsN");
  sc_trace(file, sensors[Direction::S], "sensorsS");
  sc_trace(file, sensors[Direction::E], "sensorsE");
  sc_trace(file, sensors[Direction::W], "sensorsW");
  sc_signal<int> state;
  sc_trace(file, state, "state");

  // Instantiate modules.
  Controller controller("Controller");
  Generator genN("GeneratorN", 10.0);
  Generator genS("GeneratorS", 5.0);
  Generator genW("GeneratorW", 2);
  Generator genE("GeneratorE", 0.2);

  // Connect the channels to the ports.
  controller(sensors[Direction::N], sensors[Direction::S],
             sensors[Direction::W], sensors[Direction::E], lights[Direction::N],
             lights[Direction::S], lights[Direction::W], lights[Direction::E],
             state);
  genN(sensors[Direction::N], queue_lengths[Direction::N],
       lights[Direction::N]);
  genS(sensors[Direction::S], queue_lengths[Direction::S],
       lights[Direction::S]);
  genW(sensors[Direction::W], queue_lengths[Direction::W],
       lights[Direction::W]);
  genE(sensors[Direction::E], queue_lengths[Direction::E],
       lights[Direction::E]);

  // Start the simulation.
  sc_start(sim_time);
  sc_close_vcd_trace_file(file);

  return 0;
}
