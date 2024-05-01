#import "@preview/cetz:0.2.0"
#import "@local/juro-typst:0.0.0"

#show: juro-typst.juro-report.with(
  author: "Justus Rossmeier",
  title: "TDTS07 Lab Report",
  date: datetime(year: 2024, month: 2, day: 20),
  keywords: ("Lab", "TDTS07", "LiU")
)

// if life becomes to boring, lol :D
//#show heading: set text(fill: gradient.linear(..color.map.rainbow.map(c => {c.darken(30%)})))

#outline()

= Modeling and Simulation with SystemC <sec:systemc-traffic>
== System Model (`Controller`)
The modeled crossing is depicted in @system-overview and contains one lane per incoming car, with cars only ever passing the crossing straight without turning. As soon as coming from a side, the respective sensor is activated and stays active as long as cars are waiting on that side. If the light is green, one car per second will pass the crossing, ultimately cleaning out the queue if no new cars are arriving.

#figure(caption: "System overview")[
  #cetz.canvas({
    import cetz.draw: *
    let quarter(angle, lable-anchor, name) = {
      group({
        rotate(angle * 1deg)
        //grid((-5,-5),(5,5), stroke: (dash: "dashed", paint: gray))
        line((1,0), (4,0), stroke: (dash: "loosely-dashed"))
        line((1,1), (4,1))
        line((1,-1), (4,-1))
        rect((1.3,0.1), (3.9,0.9), name: "sensor")
        rect((1,0), (1.2, 1), fill: black)
        content("sensor", angle: calc.rem(angle, 180) * 1deg, raw("Sensor" + name))
        rect((1.1, 1.1), (2.1, 1.6), name: "light")
        circle((to: "light", rel:(-.2, 0)), radius: 0.15, stroke: red, fill: red)
        circle((to: "light", rel:(.2, 0)), radius: 0.15, stroke: green)
        line("light.north-east", (to: "light.north-east", rel: (.4,.2)), mark: (start: "stealth", fill: black))
        content((rel: (0.1, 0)), anchor: lable-anchor, raw("Light"+name))
      })
    }
    quarter(0, "west", "E")
    quarter(90, "south", "N")
    quarter(180, "east", "W")
    quarter(270, "north", "S")
  })
] <system-overview>
Each sensor is modeled as an input `sc_in<bool>` and each light as an output `sc_out<int>`, where the `int` is actually an instance of the enum `LightColor` in the code but `int` is used instead to work nicely with the included tracing of SystemC.

The controller generally operates by setting a direction's light to green as long as the respective sensor indicates that cars are waiting. To ensure safe operation, the controller maintains a `state` indicating which direction cars are allowed to pass. This can be `Idle`, `NorthSouth`, or `WestEast`. Each light will only be turned green if the controller is in the respective state. If a sensor turns on and the state is idle, the state will be changed to the required state by the respective light. If the state does not permit the light to turn green, a state change will be requested and scheduled by triggering an `sc_event` after a specified `max_wait_time`. When this event is triggered, a state change is forced by first turning all lights red and then changing the state to the opposite of the previous one. If all lights turn red because no more cars are detected, the controller either changes to the other state if it has been previously requested or returns to the `Idle` state.

== Traffic Generator (`Generator`)
There are 4 traffic generators in the simulation. Each one is connected to one side of the crossing. Accordingly, the generator provides the following interface:
 - `sc_in<int> light` for getting the light signal's color relevant for the generator
 - `sc_out<bool> sensor` for feeding back sensor data to the controller
 - `sc_out<int> queue_length` for being able to trace and debug the internal queue length of the generator
The generator handles both the arrival of new cars, which occur at fixed times and are random with a likelihood depending on the generator's predefined `pressure` value
$ P_"arrival" = cases(
  min(1.0, "pressure") &"if" "queue_length" = 0,
  min(1.0, 1.0 - "queue_length"/"pressure") &"else",
) $
and the passing of cars over the crossing whenever the light signal is green. Both those events are evaluated and executed once a second with a $100 "ms"$ delay between both events to better visualize the events in the trace file.

== Testbench (`TestBench`)
The test bench contains an `sc_main` function that instantiates one `Controller` with one `Generator` per side. All relevant signals are initiated and connected to the entities as well as traced to an output file.

== Results
To verify functionality, the generator is tested with a scenario that visualizes all edge cases. To achieve reproducibility, the random generator is initialized with a fixed seed at the beginning of the simulation. To nicely reproduce edge cases, the following pressure values are used for the `Generator`s:
 - North: 10
 - South: 5
 - West: 2
 - East: 0.2
The high pressure for north and south cause a constant flow of cars from the respective directions, so both lights are essentially always green. The state is only changed after the timer for the `max_wait_time` has expired. The pressure from the west and east side is considerably lower so that sometimes the queues are emptied out and the state is changed back to `NorthSouth` before the timer's expiry. The very low pressure on the east side is additionally there to ensure that that individual light turns red when no cars are arriving anymore, even if the opposite light stays green.
@fig:traffic-plot shows the resulting traces. It can be seen that all rules and intended behaviors are fulfilled. Only opposing lights are green at the same time (value of 1 in the plot) and the periods get scheduled based on need with a maximum switching time of 10 seconds.
#figure(
  caption: "Waveforms of the simulation run",
  image("Lab1/trace.svg"),
) <fig:traffic-plot>

= Formal verification with UPPAAL
== Getting Started
 - `E<> P.s3` is satisfied as there are clearly paths that lead to the `s3` state for the automation `P`.
 - `A<> P.s3` is not satisfied. This is easier to understand using the equivalent `not E[] not P.s3` #footnote(link("https://docs.uppaal.org/language-reference/query-semantics/symb_queries/")) where it becomes quite apparent that `P` is not in `s3` on many occasions.

== Fischer
To adapt the example for higher values of `n`, the additional automats are just added to the system declarations. The query for verifying the mutex condition is generated using the python script shown in @lst:query-script.
// remove first line of code containing definition of N that is not relevant here
#let code = read("./Lab2/gen_cond.py").replace(regex("^.+?\n"), "")
#figure(
  align(left, raw(code, lang: "python")),
  caption: [ Python code for generating the queries for any $N$ ],
) <lst:query-script>
The results of the calculation times (measured with a smartphone stopwatch) are presented in @tab:fischer-runtimes. It is noteworthy that the first evaluation after altering the model is a substantially slower than subsequent evaluations. The times given are the ones of the subsequent evaluations.
#figure(
  caption: [Runtimes of the query evaluation],
  table(
    columns: (auto, auto),
    [$N$], [time (s)],
    [8], [0.42],
    [9], [0.65],
    [10], [1.0],
    [11], [3.0],
  )
) <tab:fischer-runtimes>
Linear regression with the model $"time" (N) = a dot b^N$ leads to $a = 2.32 dot 10^(-3); b = 1.88$ and thus $"time"(12) = 4.6 "s "$.

When introducing a different minimum wait time $m != k$ for the transition from `wait` to `cs`, the mutex condition holds iff $m <= k$. This makes intuitive sense because it is required that all processes have a chance to detect the foreign lock before proceeding to the critical section.

== Traffic Light Controller
The controller consists of 5 different automata, where opposing directions use the same template. The different automata used are shown in @fig:traffic-automata which also shows that the automata for the different directions are structured nearly the same, with just the synchronization channels swapped.
#figure(
  image("traffic_light.png"),
  caption: "Different automata used for modeling the traffic light controller"
) <fig:traffic-automata>
For simplicity in this model, different from the controller described in @sec:systemc-traffic, the controller does not automatically switch to the other direction if no cars are coming, but is governed by a fixed timer that alternates between both possible directions. The queries ensuring the correct operation of the controller are shown in @lst:traffic-queries although the last query exists similarly for every direction.
#figure(
  [```
    A[] not deadlock
    A[] not ((LightN.Green or LightS.Green) and (LightW.Green or LightE.Green))
    E<> LightN.Green
   ```],
   caption: "Queries used to verify the model"
) <lst:traffic-queries>

// display image with fixed pt/pixel ratio
#let img-fixed(..args, scale: 100%) = {
  let img = image(..args)
  style(styles => {
    image(..args, width: measure(img, styles).width * scale)
  })
}

== Alternating Bit Protocol
The send events (`s0`, `s1`, `sack0`, `sack1`) are modeled using synchronous channels that are written to be the sender/receiver and read by the channel. The corresponding receive events (`r0`, `r1`, `rack0`, `rack1`) are modeled as broadcast channels, as the receiver/sender might not always be able to receive them depending on their current state. To make the usage of clocks and synchronization channels more intuitive, the same logical state is partially split up in several states where all but the last are "urgent" so the synchronization still works correctly.
=== Sender
The sender automat depicted in @fig:bit-sender generates a new message after being idle for `gen = 3` time-units. Each new message is sent to the correct channel according to the current status of the sender. After sending, if the sender receives the correct ack message, it changes state and goes back to idle. If the timeout (default $5 "s "$) is reached or the wrong ack message is received, the transmission is attempted again.
#figure(
  img-fixed("bit_sender.png", scale: 55%),
  caption: "The sender",
) <fig:bit-sender>

=== Channel <sec:bit-channel>
The channel is depcited in @fig:bit-channel. It models a binary symmetrical channel for both the data as well as the ack messages. It receives any of the potential send events (`s0`, `s1`, `sack0`, `sack1`) and emits the corresponding or opposite receive event (`r0`, `r1`, `rack0`, `rack1`). The error probabilities are modeled by exploiting the fact that UPPAAL randomly chooses one of all possible edges every time. The modeled error probability $P_"error" = 1/4$ is achieved by having 3 "correct" edges and 1 "error" edge for each possible event.
#figure(
  img-fixed("bit_channel.png", scale: 55%),
  caption: "The channel",
) <fig:bit-channel>

=== Receiver
The receiver is depicted in @fig:bit-receiver. It works very similarly to the sender. When receiving the correct message for the current state, it emits the corresponding ack and changes state. When timing out or receiving the wrong message, it emits the opposite ack and goes back to waiting.
#figure(
  img-fixed("bit_receiver.png", scale: 55%),
  caption: "The receiver",
) <fig:bit-receiver>

=== Verification
The following queries are used to verify correct function
- `S.send0 --> R.recv0`: ensure that all messages sent by the sender are eventually received by the receiver. This passes with using an ideal channel, but does not pass using the binary symmetrical channel described in @sec:bit-channel.
- `R.recv0 --> C.ssack0` and `R.recv0 --> (C.rrack0 or C.rrack1)`: ensure that the receiver tries to acknoledge received messages either successfully or unsuccessfully (because of the lossy channel)
- `A[] not deadlock`: ensure that the whole system can not end up in a deadlock condition

= Design-space exploration with MPARM
== Energy Minimization
The results of the different parametrizations are shown in @tab:gsm-results. Run 1 uses the default settings of the simulator. After observing the very low cache miss rates, the cache sizes were reduced (eg. runs 2 and 3), resulting in run 2 for optimal cache sizes. Then the frequency divider was systematically increased (runs 4 to 6), with diminishing returns for a divisor larger than 6. Thus the result of run 6 is considered optimized and still contains considerable headroom to the $20 "ms"$ time limit as well.

#let results = (
([`-F0,1 --dt=4 --ds=12 --it=1 --is=13`], "45.03", "1.69", 1.13, 0.61,),
  ([`-F0,1 --dt=4 --ds=9 --it=1 --is=9`], "29.77", "1.74", 2.35, 0.92),
  ([`-F0,1 --dt=4 --ds=9 --it=1 --is=8`], "33.13", "1.94", 2.15, 2.62),
  ([`-F0,2 --dt=4 --ds=9 --it=1 --is=9`], "18.90", "3.58", 2.35, 0.92),
  ([`-F0,3 --dt=4 --ds=9 --it=1 --is=9`], "18.02", "5.10", 2.35, 0.92),
  ([`-F0,6 --dt=4 --ds=9 --it=1 --is=9`], "17.83", "9.68", 2.35, 0.92)

)
#figure(
  table(columns: (auto, auto, auto, auto, auto, auto),
    [Run], [Parameters], [Time], [Energy], [D-Miss], [I-Miss],
    ..results.enumerate(start:1).map(((i, arg)) => {
      let (cmd, e, t, dmiss, imiss) = arg
      (
        str(i),
        cmd,
        str(t) + " ms",
        str(e) + " µJ",
        str(dmiss) + " %",
        str(imiss) + " %",
      )
    }).flatten()
  ),
  caption: "Results of the different runs",
) <tab:gsm-results>

== Concurrency Optimization
Without any further modifications, the most apparent difference between the two versions is that the shared version takes more time with $14.1 "ms"$ vs $10.0 "ms"$ with the queue version. However, the queue version has a higher relative bus occupation of $56.25%$ vs $44.89%$.

To reduce the shared version's bus occupation even further, the core clocks are lowered. This is done by setting the `-Fx,y` arguments for the simulation. Lowering all core clocks by a factor of two gives a lower bus occupation of only $23.57%$ but a total runtime of $26.3 "ms"$ which does not satisfy the time requirement of $20.0 "ms"$. Using one full-speed and two half speed cores results in bus usages of around $30%$. The configuration `-F0,2 -F1,2 -F2,1` is able to complete the decoding in $18.8 "ms"$ with a bus occupation of $31.78%$.

== Mapping/Scheduling
The critical path of the problem is $"T1" --> "T3" --> "T5"$. By executing this path immediately and without any unnecessary delays between tasks, an optimal schedule can be achieved. The most straightforward solution to this problem is to execute this critical path on one processor and the other tasks (T2 and T4) on the other processor. Such a schedule with $"SL" = 35 "ms"$ is shown in @fig:schedule-rearranged.
#figure(caption: "Schedule with changed task assigments")[
  #cetz.canvas({
    import cetz.draw: *
    let task(name, proc, start, length) = {
      rect((start/5, proc*2), ((start+length)/5, proc*2+1), name: name, fill: if proc == 0 {gray} else {none})
      content(name)[#name]
    }
    line((0,-.5), (0,3.5))
    content((-.2,.5),anchor:"east")[Proc. 1]
    content((-.2,2.5),anchor:"east")[Proc. 2]
    task("T1", 0, 0, 5)
    task("T3", 0, 5, 10)
    task("T5", 0, 15, 20)
    task("T2", 1, 0, 10)
    task("T4", 1, 10, 5)
    line((1,1), (2,2), stroke: (dash: "dashed"), mark: (end: "stealth"))
    for m in (5, 15, 35) {
      content((m/5,-.1), anchor: "north")[$#m "ms"$]
    }
  })
] <fig:schedule-rearranged>
The same optimal schedule length can however also be reached while still keeping the original assignments of tasks to processors by evaluating the $"T2" --> "T4"$ path while T5 is running on the other processor. The resulting schedule in shown in @fig:schedule-orig.
#figure(caption: "Schedule with original task assignments")[
  #cetz.canvas({
    import cetz.draw: *
    let task(name, proc, start, length) = {
      rect((start/5, proc*2), ((start+length)/5, proc*2+1), name: name, fill: if proc == 0 {gray} else {none})
      content(name)[#name]
    }
    line((0,-.5), (0,3.5))
    content((-.2,.5),anchor:"east")[Proc. 1]
    content((-.2,2.5),anchor:"east")[Proc. 2]
    task("T1", 1, 0, 5)
    task("T3", 0, 5, 10)
    task("T5", 1, 15, 20)
    task("T2", 0, 15, 10)
    task("T4", 0, 25, 5)
    line((1,2), (1,1), stroke: (dash: "dashed"), mark: (end: "stealth"))
    line((3,1), (3,2), stroke: (dash: "dashed"), mark: (end: "stealth"))
    line((1,2), (5,1), stroke: (dash: "dashed"), mark: (end: "stealth"))
    for m in (5, 15, 35) {
      content((m/5,-.1), anchor: "north")[$#m "ms"$]
    }
  })
] <fig:schedule-orig>
