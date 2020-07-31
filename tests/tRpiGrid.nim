import ngspice, ngspice/parse_netlist
import wiringPiMock

import unittest, os, strutils, strformat

suite "RPI simulation":
  test "Diode grid":
    const srcd = currentSourcePath().parentDir()
    var doc = parseNGDoc(srcd.joinpath "key-grid.net")
    doc.included = @[
      srcd.joinpath "on-off-switch.net",
      srcd.joinpath "io-pin.net"
    ]

    ngSpiceInit(
      printfcn = (proc(m: string, a2: int): int =
                      if not m.startsWith("stdout *"): echo "@ ", m
                 ).addPtr(),
      statfcn = (proc(m: string, a2: int): int = discard).addPtr(),
      sdata = proc(vdata: VecValuesAll, a2: int, a3: int, a4: pointer): int =
        echo &"Done [{vdata.vecindex}/{vdata.veccount}]"

    )

    doc.setPinStates(
      {
        1: psWriteHigh,
        2: psWriteHigh,
        3: psWriteHigh,

        4: psRead,
        5: psRead,
        6: psRead,
      }
    )


    for p in doc.getPinValues():
      echo &"{p.index}[{p.state}]: {p.voltage.toEngNotation()}"

    doc.setPinStates(
      {
        1: psWriteLow,
      }
    )

    doc.setSwitchStates(
      {
        "c1r1": true
      }
    )

    for p in doc.getPinValues():
      echo &"{p.index}[{p.state}]: {p.voltage.toEngNotation()}"
