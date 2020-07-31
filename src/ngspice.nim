## Wrapper for ngspice library

import sequtils
import math, complex
import sugar, strutils, strformat
import os

{.passl: "-lngspice" .}

const srcd = currentSourcePath().parentDir()
const hdr = joinpath(srcd, "sharedspice.h")

type
  CArray[T] = UncheckedArray[T]

#==============================  vecvalues  ==============================#

type
  VecValues_Impl {.header(hdr), importc: "vecvalues".} = object
    name: cstring
    creal: cdouble
    cimag: cdouble
    is_scale: bool
    is_complex: bool

  VecValue = object
    creal: float
    cimag: float
    isScale: bool
    isComplex: bool

converter toVecValue(impl: VecValues_Impl): VecValue =
  VecValue(
    creal: impl.creal,
    cimag: impl.cimag,
    isScale: impl.is_scale,
    isComplex: impl.is_complex
  )

#============================  vecvaluesall  =============================#

type
  VecValuesAll_Impl* {.header(hdr), importc: "vecvaluesall".} = object
    veccount*: cint
    vecindex*: cint
    vecsa*: CArray[VecValues_Impl]

  VecValuesAll* = object
    vecindex*: int
    veccount*: int
    values*: seq[VecValue]

converter toVecValuesAll(impl: VecValuesAll_Impl): VecValuesAll =
  VecValuesAll(
    vecindex: impl.vecindex,
    veccount: impl.veccount
  )

#===============================  vecinfo  ===============================#

type
  NGVecInfo_Impl {.header(hdr), importc: "vecinfoall".} = object
    name: cstring
    title: cstring
    date: cstring
    `type`: cstring
    veccount: cint

  NGVecInfo* = object
    name*: string
    title*: string
    date*: string
    veccount*: int
    vtype*: string

converter toNGVecInfo(impl: NGVecInfo_Impl): NGVecInfo =
  NGVecInfo(
    name: $impl.name,
    title: $impl.title,
    veccount: impl.veccount,
    vtype: $impl.`type`,
    date: $impl.date
  )

#=============================  vector info  =============================#

type
  NGComplex {.header(hdr), importc: "ngcomplex".} = object
    cx_real: cdouble
    cx_imag: cdouble

  NGVectorInfo_Impl {.header(hdr), importc: "vector_info".} = object
    v_name: cstring ## Same as so_vname.
    v_type: cint ## Same as so_vtype.
    v_flags: cshort ## Flags (a combination of VF_*).
    v_realdata: CArray[cdouble] ## Real data.
    v_compdata: CArray[NGComplex] ## Complex data.
    v_length: cint ## Length of the vector.

  NGVectorInfo* = object
    name*: string
    vtype*: int
    flags*: int
    realdata*: seq[float]
    compdata*: seq[Complex[float]]
    length*: int

converter toComplex(val: NGComplex): Complex[float] =
  Complex[float](
    re: val.cx_real,
    im: val.cx_imag
  )

converter toNGVectorInfo(impl: NGVectorInfo_Impl): NGVectorInfo =
  NGVectorInfo(
    name: $impl.v_name,
    vtype: impl.v_type,
    flags: impl.v_flags,
    realdata: (
      block:
        collect(newSeq):
          for i in 0 ..< impl.v_length: impl.v_realdata[i])
  )

#==============================  callbacks  ==============================#

type
  NGSendDataCb_Impl = proc(
    a1: ptr VecValuesAll_Impl, a2: cint, a3: cint, a4: pointer): cint {.cdecl.}

  NGSendDataCb = proc(
    a1: VecValuesAll, a2: int, a3: int, a4: pointer): int

  NGSendCharCb_Impl = proc(a1: cstring, a2: cint, a3: pointer): cint {.cdecl.}
  NGSendCharCb = proc(a1: string, a2: int, a3: pointer): int

  NGSendStatCb_Impl = proc(a1: cstring, a2: cint, a3: pointer): cint {.cdecl.}
  NGSendStatCb = proc(a1: string, a2: int, a3: pointer): int

  NGControlledExitCb_Impl = proc(
    a1: cint, a2: bool, a3: bool, a4: cint, a5: pointer): cint {.cdecl.}

  NGControlledExitCb = proc(
    a1: int, a2: bool, a3: bool, a4: int, a5: pointer): int

  NGSendInitDataCb_Impl = proc(
    a1: ptr NGVecInfo_Impl, a2: cint, a3: pointer): cint {.cdecl.}

  NGSendInitDataCb = proc(
    a1: NGVecInfo, a2: int, a3: pointer): int

  NGBGThreadRunningCb_Impl = proc(
    a1: bool, a2: cint, a3: pointer): cint {.cdecl.}

  NGBGThreadRunningCb = proc(a1: bool, a2: int, a3: pointer): int

proc ngPrintPassthrough_Impl(a1: cstring, a2: cint, a3: pointer): cint {.cdecl.} =
  echo a1
  return 0

proc ngPrintPassthrough(a1: string, a2: int, a3: pointer): int =
  echo a1

proc ngDefaultExit_Impl(
  a1: cint, a2: bool, a3: bool, a4: cint, a5: pointer): cint {.cdecl.} =
    discard

proc ngDefaultExit(
  a1: int, a2: bool, a3: bool, a4: int, a5: pointer): int =
    discard

proc ngNoMultithreading_Impl(a1: bool, a2: cint, a3: pointer): cint {.cdecl.} =
  return 0
proc ngNoMultithreading(a1: bool, a2: int, a3: pointer): int =
  return 0


var currentVeccount: int = 0

proc ngDefaultSendInitData_Impl(
  a1: ptr NGVecInfo_Impl, a2: cint, a3: pointer): cint {.cdecl.} =
  currentVeccount = a1.veccount

proc ngDefaultSendInitData(
  a1: NGVecInfo, a2: int, a3: pointer): int =
  currentVeccount = a1.veccount

proc ngDefaultSendData_Impl(
  a1: ptr VecValuesAll_Impl, a2: cint, a3: cint, a4: pointer): cint {.cdecl.} =
    discard

proc ngDefaultSendData(
  a1: VecValuesAll, a2: int, a3: int, a4: pointer): int =
    discard

proc ngSpiceInit_Impl(
  printfcn: NGSendCharCb_Impl = ngPrintPassthrough_Impl,
  statfcn: NGSendStatCb_Impl = ngPrintPassthrough_Impl,
  ngexit: NGControlledExitCb_Impl = ngDefaultExit_Impl,
  sdata: NGSendDataCb_Impl = ngDefaultSendData_Impl,
  sinitdata: NGSendInitDataCb_Impl = ngDefaultSendInitData_Impl,
  bgtrun: NGBGThreadRunningCb_Impl = ngNoMultithreading_Impl,
  userData: pointer = nil
                     ) {.importc("ngSpice_Init"), header(hdr).}

func addPtr*[T1, T2, T3](
  arg: proc(a1: T1, a2: T2): T3): proc(a1: T1, a2: T2, a3: pointer): T3 =
  proc tmp(a1: T1, a2: T2, a3: pointer): T3 =
    arg(a1, a2)

  tmp


proc ngSpiceInit*(
  printfcn: NGSendCharCb = ngPrintPassthrough,
  statfcn: NGSendStatCb = ngPrintPassthrough,
  ngexit: NGControlledExitCb = ngDefaultExit,
  sdata: NGSendDataCb = ngDefaultSendData,
  sinitdata: NGSendInitDataCb = ngDefaultSendInitData,
  bgtrun: NGBGThreadRunningCb = ngNoMultithreading,
  userData: pointer = nil
                     ) =

  ngSpiceInit_Impl(
    printfcn = (
      block:
        var printfcn_cb {.global.}: NGSendCharCb
        printfcn_cb = printfcn

        proc ng_printfcn(
          a1: cstring, a2: cint, a3: pointer): cint {.cdecl.} =
            discard printfcn_cb($a1, a2, a3)

        ng_printfcn
    ),
    statfcn = (
      block:
        var statfcn_cb {.global.}: NGSendStatCb
        statfcn_cb = statfcn

        proc ng_statfcn(
          a1: cstring, a2: cint, a3: pointer): cint {.cdecl.} =
            discard statfcn_cb($a1, a2, a3)

        ng_statfcn
    ),
    ngexit = (
      block:
        var cb {.global.}: NGControlledExitCb
        cb = ngexit

        proc impl(
          a1: cint, a2: bool, a3: bool, a4: cint, a5: pointer): cint {.cdecl.} =
            discard cb(a1, a2, a3, a4, a5)

        impl
    ),
    sinitdata = (
      block:
        var cb {.global.}: NGSendInitDataCb
        cb = sinitdata

        proc impl(
          a1: ptr NGVecInfo_Impl, a2: cint, a3: pointer): cint {.cdecl.} =
            discard cb(a1[], a2, a3)

        impl
    ),
    sdata = (
      block:
        var sdata_cb {.global.}: NGSendDataCb
        sdata_cb = sdata

        proc ng_data(
          a1: ptr VecValuesAll_Impl, a2: cint, a3: cint, a4: pointer): cint {.cdecl.} =
            discard sdata_cb(a1 = a1[], a2 = a2, a3 = a3, a4 = a4)

        ng_data),
    bgtrun = (
      block:
        var cb {.global.}: NGBGThreadRunningCb
        cb = bgtrun

        proc impl(
          a1: bool, a2: cint, a3: pointer): cint {.cdecl.} =
            discard cb(a1, a2, a3)

        impl
    )
  )


proc ngSpiceCommand_Impl(
  a1: cstring): cint {.importc("ngSpice_Command"), header(hdr).}

proc ngspiceCommand*(arg: string): int {.discardable.} =
  ## Run ngspice command
  var str = allocCStringArray([arg])
  result = ngSpiceCommand_Impl(a1 = str[0])
  deallocCStringArray(str)

proc ngSpice_Circ_Impl(circarray: cstringArray): cint
  {.importc("ngSpice_Circ"), header(hdr).}

proc ngSpiceCirc*(circarray: seq[string],
  header: string = "Circuit simulation", footer: string = ".end"
                ): int {.discardable.} =

  # arr[circarray.len + 3] = cast[cstring](0)
  let input = @[header] & circarray & @[footer] & @[""]
  let arr = allocCStringArray(input)
  arr[input.len - 1] = cast[cstring](0)
  result = ngSpice_Circ_Impl(arr)
  # deallocCStringArray(arr)

proc ngSpiceAllVecs_Impl(pltname: cstring): cstringArray
  {.importc("ngSpice_AllVecs"), header(hdr).}

proc ngSpiceAllVecs(pltname: string): seq[string] =
  ## Get vector names associated with plot
  let cpltname = allocCStringArray([pltname])
  let tmp = ngSpiceAllVecs_Impl(cpltname[0])

  for i in 0 ..< currentVeccount:
    result.add $tmp[i]

  deallocCStringArray(cpltname)


proc ngSpiceCurPlot_Impl(): cstring {.importc("ngSpice_CurPlot"), header(hdr).}
proc ngSpiceCurPlot*(): string =
  ## Get name of the last simulated plot
  $ngSpiceCurPlot_Impl()

proc ngGet_Vec_Info_Impl(plotvecname: cstring): ptr NGVectorInfo_Impl
  {.importc("ngGet_Vec_Info"), header(hdr).}

proc ngGetVecInfo(plotvecname: string): NGVectorInfo =
  let cplotvecname = allocCStringArray([plotvecname])
  let impl = ngGet_Vec_Info_Impl(cplotvecname[0])
  result = impl[]
  deallocCStringArray(cplotvecname)

proc ngSpiceCurVectorsR*(): seq[(string, seq[float])] =
  ## Get real vector values from last command
  let plt = ngSpiceCurPlot()
  for vec in ngSpiceAllVecs(plt):
    result.add((vec, ngGetVecInfo(plt & "." & vec).realdata))
  discard


when isMainModule:
  ngspiceInit(
    printfcn = (proc(msg: string, a2: int): int = echo "@ ", msg).addPtr(),
    statfcn = (proc(msg: string, a2: int): int = echo "# ", msg).addPtr(),
    sdata =
      proc(vdata: VecValuesAll, a2: int, a3: int, a4: pointer): int =
        echo &"Porcessed {vdata.vecindex}/{vdata.veccount} vectors"
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
