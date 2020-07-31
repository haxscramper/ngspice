{.define(shellThrowException).}

import tables, options, sugar, sorta
import times
import math
import strscans
import os
import parseutils
import re
import strutils
import hmisc/helpers
import sequtils, strformat
import shell
import posix_utils
import ngspice
# import hmisc/defensive
import hmisc/hexceptions

const srcd = currentSourcePath().parentDir()
# initDefense()

# type
#   ExternalSourceError = ref object of CatchableError
#   ShellExecError = ref object of ExternalSourceError
#     retcode: int ## Return code of failed command
#     errmsg: string ## Shell command error message
#     shellcmd: string ## Shell command


template tryShellRun(body: untyped): string =
  let (res, err, code) = shellVerboseErr:
    body

  res

template withCwd(cwd: string, body: untyped): untyped =
  ## Store current directory, switch to `cwd`, execute body and switch
  ## back
  let nowDir = getCurrentDir()
  setCurrentDir(cwd)

  body

  setCurrentDir(nowDir)






type
  OptStr = Option[string]
  OptInt = Option[int]

type
  PinState* = enum
    psWriteLow = 0
    psWriteHigh = 1

    psRead = 2
    psReadPullup = 3
    psReadPulldown = 4

  NGInstanceKind = enum
    ngdResistor
    ngdDiode

    ngdVoltageSource

    ngdCustom

    ngdVoltageSwitch

    ngdPin
    ngdOnOffSwitch

  NGInstance* = object
    name*: string ## Alphanumeric name of the instance
    terms*: seq[int] ## Connected terminals
    modelName*: OptStr ## Name of the model
    params*: Table[string, string] ## Additional parameters, not
                                  ## specified in the type.

    case kind*: NGInstanceKind:
      of ngdResistor:
        resistance*: int
      of ngdVoltageSwitch:
        initStage*: bool
      of ngdVoltageSource:
        voltage*: float
      of ngdPin:
        iomode*: PinState
      of ngdOnOffSwitch:
        isOn*: bool
      of ngdCustom, ngdDiode:
        nil

  NGModel = object
    kind: NGInstanceKind
    name: string
    params: Table[string, string]

  NGNodeKind = enum
    ngnInstance
    ngnControl
    ngnModel

  NGNode = object
    case kind: NGNodeKind:
      of ngnControl:
        beginEnd: (string, string)
      of ngnInstance:
        dev: NGInstance
      of ngnModel:
        model: NGModel

  NGDocument* = object
    included*: seq[string]
    nodes*: seq[NGNode]

type

  PinVal* = object
    voltage*: float
    state*: PinState
    index*: int

func getTerminals(dev: NGInstance): (int, int) =
  ## Returng `N+` and `N-` pins for the node.
  (dev.terms[0], dev.terms[1])

# func `$`(n: NGNNode) = ...

proc parseIntSeq(s: seq[string],
                inclusive: (int, int) | int,
                onMissing: string): seq[int] =
  ## Parse sequence of strings into integers and throw exception if
  ## number of items is less than necessary.
  when inclusive is int:
    longAssertionCheck(s.len >= inclusive):
      """Error while parsing integer sequence. Cannot access {inclusive} index
      as sequence has len {s.len}. {onMissing}"""

    try:
      result = @[s[inclusive].parseInt()]
    except:
      longAssertionFail:
        """Failed to parse s[{inclusive}] as integer:
        {getCurrentExceptionMsg()}. {onMissing}"""

  else:
    longAssertionCheck(s.len >= inclusive[1]):
      """Error while parsing integer sequence: sequnce length is too small:
      expected {inclusive[1]}, but found {s.len} """

  longValueCheck(inclusive[1] < s.len):
      "Error while parsing intergers: expected {inclusive[1]} elements but found {s.len}. {onMissing}"

  for i in inclusive[0] .. inclusive[1]:
    result.add s[i].parseInt()

func filterEmpty(s: seq[string]): seq[string] =
  ## Filter out stirng that contains only whitespace characters ([\s])
  s.filterIt(it =~ re"[^\s]")

func joinkv[K, V](t: Table[K, V], eqTok: string = "="): seq[string] =
  ## Join table values as key-value pairs
  collect(newSeq):
    for k, v in t: &"{k} {eqTok} {v}"

func toString(kind: NGInstanceKind): char =
  case kind:
    of ngdDiode: 'D'
    of ngdResistor: 'R'
    of ngdCustom, ngdPin, ngdOnOffSwitch: 'X'
    of ngdVoltageSwitch: 'S'
    of ngdVoltageSource: 'V'

func toInstanceKind(kind: string): NGInstanceKind =
  case kind[0].toLowerAscii():
    of 'd': ngdDiode
    of 'r': ngdResistor
    of 'v': ngdVoltageSource
    of 'x': ngdCustom
    of 's': ngdVoltageSwitch
    else:
      longValueFail: "Unknown instance kind: '{kind[0]}'"

iterator asKVTokens(s: seq[string], eqTok: string = "="): tuple[k, v: string] =
  ## Iterate sequence of key-value tokens
  # TODO handle cases like `k=v`, `k= v` and `k =v` (pair passed as
  # one or two tokens)
  for kIdx in 0 ..< (s.len div 3):
    let idx = kIdx * 3
    longAssertionCheck(s[idx + 1] == eqTok):
      "Invalid equality token: expected {eqTok}, found {s[idx + 1]} at [{idx + 1}]"

    yield (s[idx], s[idx + 2])


proc parseNGModel(config: seq[string]): NGModel =
  let tokens = config.joinw().split(" ").filterEmpty()
  result.name = tokens[1]
  result.kind = tokens[2].toInstanceKind()
  for k, v in tokens[3..^1].asKVTokens():
    result.params[k] = v

template takeItUntil(s: untyped, pr: untyped): untyped =
  var res: seq[type(s[0])]
  for it {.inject.} in s:
    if not pr:
      res.add it
    else:
      break

  res

proc convertUntilEx[T, R](
  s: openarray[T], conv: proc(arg: T): R): tuple[res: seq[R], idx: int] =
  ## Run conversion until exeption is thrown. `counter` will be
  ## assigned to an **index of first failed** item in sequence.
  for idx, it in s:
    try:
      result.res.add conv(it)
    except:
      result.idx = idx
      break

assert @["12", "99", "%%%", "90"].convertUntilEx(
  parseInt) == (@[12, 99], 2)

func splitTupleFirst*[T, R](tupl: (T, R), second: var R): T =
  result = tupl[0]
  second = tupl[1]

func splitTupleSecond*[T, R](tupl: (T, R), second: var T): R =
  result = tupl[1]
  second = tupl[0]


template convertItUntilEx(
  s: untyped, conv: untyped, counter: var int = 0): untyped =
  ## Run conversion until exception is thrown `counter` will be
  ## assigned to an **index of first failed** item in sequence.
  runnableExamples:
    import strutils

    var idx = 0
    assert @["12", "99", "%%%", "90"].convertItUntilEx(
      parseInt(it), idx) == @[12, 99]

    assert idx == 2

  var res: seq[type(
    block:
      var it {.inject.}: type(s[0])
      conv
  )]

  for idx, it {.inject.} in s:
    try:
      res.add conv
    except:
      counter = idx
      break

  res


func getNth[T](s: openarray[T], n: int, onErr: string): T =
  longAssertionCheck(s.len > n):
    onErr

  return s[n]

proc parseEng*(val: string): float =
  var numBuf: seq[char]
  var prefix: char
  var unit: seq[char]
  var idx: int = 0

  discard scanp(val, idx,
            +({'0' .. '9'} -> numBuf.add($_)),
            {
              'Y', 'Z', 'E', 'P', 'T', 'G', 'M', 'k', 'K', # > 1
              'm', 'u', 'n', 'p', 'f', 'a', 'z', 'y'  # < 1
            } -> (prefix = $_),
            *({'a' .. 'z'} -> unit.add($_))
  )

  let base: float = 1000
  let multiple =
    case prefix:
      of 'Y':      base.pow 8
      of 'Z':      base.pow 7
      of 'E':      base.pow 6
      of 'P':      base.pow 5
      of 'T':      base.pow 4
      of 'G':      base.pow 3
      of 'M':      base.pow 2
      of 'k', 'K': base.pow 1
      of 'm':      base.pow -1
      of 'u':      base.pow -2
      of 'n':      base.pow -3
      of 'p':      base.pow -4
      of 'f':      base.pow -5
      of 'a':      base.pow -6
      of 'z':      base.pow -7
      of 'y':      base.pow -8
      else: 1

  result = numBuf.join().parseInt().toFloat() * multiple

proc toEngNotation*(val: float): string =
  let power = floor log(val, 1000)

  let pref = case power:
    of 8: 'Y'
    of 7: 'Z'
    of 6: 'E'
    of 5: 'P'
    of 4: 'T'
    of 3: 'G'
    of 2: 'M'
    of 1: 'K'
    of -1: 'm'
    of -2: 'u'
    of -3: 'n'
    of -4: 'p'
    of -5: 'f'
    of -6: 'a'
    of -7: 'z'
    of -8: 'y'
    else: ' '

  if power == 0:
    return $round(val)
  else:
    return $round(val / power) & pref


proc parseNgnNode(lns: seq[(int, string)]): NGNode =
  let lineIdx = lns[0][0]
  let config: seq[string] = lns
    .mapIt(it[1])
    .mapIt(it.startsWith("+").tern(it[1..^1], it))
    .join(" ")
    .split(" ")

  let first = config[0]
  if first.startsWith("."): # Control node
    case first.toLowerAscii():
      of ".model":
        result = NGNode(kind: ngnModel, model: parseNGModel(config))
  else:
    let name = first[1..^1]
    let resDev: NGInstance =
      case first[0].toLowerAscii():
        of 'r':
          NGInstance(
            kind: ngdResistor,
            name: first[1..^1],
            terms: config.parseIntSeq(
              (1, 2), &"Resistor missing connection pin on line {lineIdx}"),
            resistance: config.getNth(
                  3, &"Resistor missing value on line {lineIdx}")
                  .parseEng().toInt()
          )

        of 'x':
          var modelIdx: int = 0
          let terms = config[1..^1].convertUntilEx(parseInt).splitTupleFirst(modelIdx)
          let model = config[modelIdx + 1]
          case model:
            of "pin":
              NGInstance(
                kind: ngdPin,
                terms: terms,
                name: name,
                modelName: some(model)
              )
            of "on_off_switch":
              NGInstance(
                kind: ngdOnOffSwitch,
                terms: terms,
                name: name,
                modelName: some(model)
              )
            else:
              NGInstance(
                kind: ngdCustom,
                terms: terms,
                name: first[1..^1],
                modelName: some(model)
              )
        of 'd':
          NGInstance(
            kind: ngdDiode,
            terms: config.parseIntSeq(
              (1, 2), &"Diode missing conneciton pin on line {lineIdx}"),
            name: first[1..^1],
            modelName: some(config[3])
          )

        of 'v':
          NGInstance(
            kind: ngdVoltageSource,
            name: first[1..^1],
            terms: config.parseIntSeq(
              (1, 2), &"Voltage source missing connection pin on line {lineIdx}"),
            voltage: config.getNth(
              3, &"Voltage source missing value on line {lineIdx}")
              .parseEng()
          )
        else:
          longValueFail:
            "Unknow device type: {first[0]}"

    result = NGNode(kind: ngnInstance, dev: resDev)

proc toString(node: NGNode): string =
  case node.kind:
    of ngnModel:
      let modl = node.model
      result = &".MODEL {modl.name} {modl.kind.toString()}\n" &
        &"{modl.params.joinkv().mapIt(\"+ \" & it).joinl()}"

    of ngnInstance:
      let inst = node.dev
      let dtype =
        case inst.kind:
          of ngdResistor: "R"
          of ngdDiode: "D"
          of ngdCustom, ngdPin, ngdOnOffSwitch: "X"
          of ngdVoltageSource: "V"
          of ngdVoltageSwitch: "S"

      let deviceSpecific =
        case inst.kind:
          of ngdResistor: $inst.resistance
          of ngdVoltageSource: $inst.voltage
          of ngdOnOffSwitch: &"state={inst.isOn.tern(1, 0)}"
          of ngdPin: &"state={cast[int](inst.iomode)}"
          else: ""

      result = @[
          dtype & inst.name,
          inst.terms.mapIt($it).join(" "),
          inst.modelName.get(""),
          deviceSpecific,
          inst.params.joinkv().joinw()
        ].joinw


    of ngnControl:
      result = "control"

proc parseNGDoc*(path: string): NGDocument =
  let netlist = toSeq(path.lines)
    .enumerate()
    .filterIt(not it[1].startsWith("*"))
    .mapIt((it[0], it[1]))

  result.nodes =
    block:
      var res: seq[NGNode]
      var buf: seq[(int, string)]
      for line in netlist:
        if line[1].startsWith("+"): # Multiline card continuation
          buf.add line
        else:
          if buf.len == 0: # Might be a start of a new mulitline
            buf.add line
          else: # New card
            res.add parseNgnNode(buf)
            buf = @[line]

      res

var simIdx = 0
proc simulate*(doc: NGDocument): Table[string, seq[float]] =
  var circ: seq[string]

  for incld in doc.included:
    circ.add "* included " & incld
    circ.add incld.readFile().string()

  circ.add doc.nodes.map(toString).joinl

  circ.add "Vdummy 0 999 5"
  circ.add ".dc vdummy 0 0 5"

  (&"/tmp/circ-{simIdx}.net").writeFile(circ.joinl)
  # showLog &"Simulation #{simIdx}"
  inc simIdx

  ngSpiceCirc(circarray = circ.joinl().split("\n"))

  ngSpiceCommand("run")

  result = ngSpiceCurVectorsR().toTable()


iterator iterateMDevices(doc: var NGDocument): var NGInstance =
  for node in mitems(doc.nodes):
    if node.kind == ngnInstance:
      yield node.dev

iterator iterateDevices(doc: NGDocument): NGInstance =
  for node in doc.nodes:
    if node.kind == ngnInstance:
      yield node.dev

proc setPinStates*(doc: var NGDocument, values: varargs[(string, PinState)]): void =
  # TODO throw exception on missing pin name
  let newvals = values.toTable()
  for dev in iterateMDevices(doc):
    if dev.kind == ngdPin:
      if newvals.hasKey(dev.name):
        dev.iomode = newvals[dev.name]

proc setPinStates*(doc: var NGDocument, values: varargs[(int, PinState)]): void =
  # TODO throw exception on missing pin name
  doc.setPinStates(values.mapIt(($it[0], it[1])))

proc getPinStates*(doc: NGDocument): Table[int, PinState] =
  ## Get current pin configurations
  for dev in iterateDevices(doc):
    if dev.kind == ngdPin:
      result[dev.name.parseInt()] = dev.iomode

proc setSwitchStates*(doc: var NGDocument, values: varargs[(string, bool)]): void =
  let newvals = values.toTable()
  for dev in iterateMDevices(doc):
    if dev.kind == ngdOnOffSwitch:
      if newvals.hasKey(dev.name):
        dev.isOn = newvals[dev.name]

proc getPinValues*(doc: NGDocument): seq[PinVal] =
  let vectors = doc.simulate()
  var termVals: SortedTable[int, seq[float]]

  # Mapping betwen pin index and it's corresponding terminal node.
  # `terminal -> pin index`
  var pinIdxMap: Table[int, int]
  var pinStates: Table[int, PinState]

  block:
    let pinTerms =
      collect(newSeq):
        for node in doc.nodes:
          if node.kind == ngnInstance and node.dev.modelName == "pin":
            let term = node.dev.terms[0]
            pinIdxMap[term] = node.dev.name.parseInt()
            pinStates[term] = node.dev.iomode
            term

    for name, vals in vectors:
      if name =~ re"V\((\d+)\)":
        let idx = matches[0].parseInt()
        if idx in pinTerms:
          termVals[idx] = vals


  for term, val in termVals:
    result.add PinVal(
      index: pinIdxMap[term],
      state: pinStates[term],
      voltage: val[0]
    )

proc main(): void =
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


when isMainModule:
  prettyStackTrace:
    main()
