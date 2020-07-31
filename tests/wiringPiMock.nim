## Simulate connected pins using ngspice simulation

import ngspice, ngspice/parse_netlist
import tables, times, math
import strutils, strformat

var document: NGDocument
var silent: bool = false

proc ngReadCircuit*(path: string): void =
  document = parseNGDoc(path)

proc ngAddIncluded*(files: seq[string]): void =
  document.included.add files

proc ngSilentSimulation*(arg: bool = true): void =
  silent = arg

proc setSwitch*(row, col: int, state: bool = off): void =
  let name = &"c{col}r{row}"
  # showInfo &"Set switch '{name}' to state '{state}'"
  document.setSwitchStates({
    name : state
  })

proc piSetup*(): cint =
  result = 0

  ngSpiceInit(
    printfcn = (
      proc(msg: string, a2: int): int =
        if (not msg.startsWith("stdout *")) and (not silent):
          echo msg
          # showLog(msg)
    ).addPtr(),
    statfcn = (
      proc(msg: string, a2: int): int = discard
    ).addPtr()
  )

converter toInt(c: cint): int = cast[int](c)

proc piSetupGPIO*(): cint = 0
proc piSetupPhys*(): cint = 0
proc piSetupSys*(): cint = 0

proc piPinModeOutput*(pin: cint) =
  document.setPinStates({
    pin.toInt() : psWriteLow
  })

proc piPinModeInput*(pin: cint) =
  document.setPinStates({
    pin.toInt() : psRead
  })


proc piPinModeGPIO*(pin: cint) = discard
proc piPinModePWM*(pin: cint) = discard
proc piDigitalPWM*(pin, value: cint) = discard

proc piDigitalWrite*(pin, value: cint) =
  assert document.getPinStates()[pin] in {psWriteLow, psWriteHigh}, &"""
    Misconfigured pin: need psWriteLow or psWriteHigh,
    but found {document.getPinStates()[pin]}
    """

  document.setPinStates({
    pin.toInt() : (if value == 0: psWriteLow else: psWriteHigh)
  })



proc piDigitalRead*(pin: cint): cint =
  let pc = document.getPinStates()[pin]
  assert pc in {psRead, psReadPullup}, &"""
    Misconfigured pin: need psRead, but found {pc}
    """

  let t0 = cpuTime()
  let pinValues = document.getPinValues()

  if not silent:
    echo(
      "Simulation completed in ",
      round((cpuTime() - t0) * 1000 * 10) / 10,
      "ms"
    )

  for pinv in pinValues:
    if pinv.index == pin:
      if abs(pinv.voltage) <= 0.05:
        # showLog &"V({pin}) =", toRed(&"{pinv.voltage:>2.3f}")
        return 0
      else:
        # showLog &"V({pin}) =", toGreen(&"{pinv.voltage:>2.3f}")
        return 1

proc piPullOff*(pin: cint) = discard

proc piPullDown*(pin: cint) =
  document.setPinStates({
    pin.toInt() : psReadPulldown
  })

proc piPullUp*(pin: cint) =
  document.setPinStates({
    pin.toInt() : psReadPullup
  })

proc analogWrite*(pin, value: cint) = discard
proc analogRead*(pin: cint): cint = 0
