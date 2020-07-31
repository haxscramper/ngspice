import unittest, strformat
import ngspice

suite "Api test":
  test "can add":
    ngspiceInit(
      printfcn = (proc(msg: string, a2: int): int = echo "@ ", msg).addPtr(),
      statfcn = (proc(msg: string, a2: int): int = echo "# ", msg).addPtr(),
      sdata =
        proc(vdata: VecValuesAll, a2: int, a3: int, a4: pointer): int =
          echo &"Processed {vdata.vecindex}/{vdata.veccount} vectors"
    )

    ngSpiceCirc(
      @[
        "V1 0 1 5",
        "V2 0 2 5",
        "R1 0 1 10",
        "R2 0 2 10",
        ".dc v1 0 5 1"
      ]
    )

    ngSpice_Command("run");

    let cp = ngSpiceCurPlot()
    for vec in ngSpiceAllVecs(cp):
      let res = ngGetVecInfo(cp & "." & vec)
      echo vec, ":  ", res.realdata

    echo "done"
