v 20191008 2
C 40000 40000 0 0 0 title-B.sym
C 49300 48700 1 90 0 io-pin-1.sym
{
T 49200 48700 5 10 1 1 90 0 1
refdes=X3
T 49300 49400 5 10 0 1 90 0 1
model-name=pin
}
C 47300 48700 1 90 0 io-pin-1.sym
{
T 47200 48700 5 10 1 1 90 0 1
refdes=X2
T 47300 49400 5 10 0 1 90 0 1
model-name=pin
}
C 45300 48700 1 90 0 io-pin-1.sym
{
T 45200 48700 5 10 1 1 90 0 1
refdes=X1
T 45300 49400 5 10 0 1 90 0 1
model-name=pin
}
C 41800 42200 1 180 0 io-pin-1.sym
{
T 41800 42100 5 10 1 1 180 0 1
refdes=X7
T 41100 42200 5 10 0 1 180 0 1
model-name=pin
}
C 41800 44200 1 180 0 io-pin-1.sym
{
T 41800 44100 5 10 1 1 180 0 1
refdes=X6
T 41100 44200 5 10 0 1 180 0 1
model-name=pin
}
C 41800 46200 1 180 0 io-pin-1.sym
{
T 41800 46100 5 10 1 1 180 0 1
refdes=X5
T 41100 46200 5 10 0 1 180 0 1
model-name=pin
}
C 44100 47100 1 270 0 diode-1.sym
{
T 44700 46700 5 10 0 0 270 0 1
device=DIODE
T 44100 47100 5 10 0 0 0 0 1
model-name=1N4148
T 44600 46800 5 10 1 1 270 0 1
refdes=Dc1r1
}
C 44100 45100 1 270 0 diode-1.sym
{
T 44700 44700 5 10 0 0 270 0 1
device=DIODE
T 44100 45100 5 10 0 0 0 0 1
model-name=1N4148
T 44600 44800 5 10 1 1 270 0 1
refdes=Dc1r2
}
N 45300 43100 45300 48700 4
N 41800 44200 50300 44200 4
C 44100 43100 1 270 0 diode-1.sym
{
T 44700 42700 5 10 0 0 270 0 1
device=DIODE
T 44100 43100 5 10 0 0 0 0 1
model-name=1N4148
T 44600 42800 5 10 1 1 270 0 1
refdes=Dc1r3
}
N 41800 42200 50300 42200 4
C 46100 47100 1 270 0 diode-1.sym
{
T 46700 46700 5 10 0 0 270 0 1
device=DIODE
T 46100 47100 5 10 0 0 0 0 1
model-name=1N4148
T 46600 46800 5 10 1 1 270 0 1
refdes=Dc2r1
}
C 46100 45100 1 270 0 diode-1.sym
{
T 46700 44700 5 10 0 0 270 0 1
device=DIODE
T 46100 45100 5 10 0 0 0 0 1
model-name=1N4148
T 46600 44800 5 10 1 1 270 0 1
refdes=Dc2r2
}
N 47300 43100 47300 48700 4
C 46100 43100 1 270 0 diode-1.sym
{
T 46700 42700 5 10 0 0 270 0 1
device=DIODE
T 46100 43100 5 10 0 0 0 0 1
model-name=1N4148
T 46600 42800 5 10 1 1 270 0 1
refdes=Dc2r3
}
C 48100 47100 1 270 0 diode-1.sym
{
T 48700 46700 5 10 0 0 270 0 1
device=DIODE
T 48100 47100 5 10 0 0 0 0 1
model-name=1N4148
T 48600 46800 5 10 1 1 270 0 1
refdes=Dc3r1
}
C 48100 45100 1 270 0 diode-1.sym
{
T 48700 44700 5 10 0 0 270 0 1
device=DIODE
T 48100 45100 5 10 0 0 0 0 1
model-name=1N4148
T 48600 44800 5 10 1 1 270 0 1
refdes=Dc3r2
}
N 49300 43100 49300 48700 4
C 48100 43100 1 270 0 diode-1.sym
{
T 48700 42700 5 10 0 0 270 0 1
device=DIODE
T 48100 43100 5 10 0 0 0 0 1
model-name=1N4148
T 48600 42800 5 10 1 1 270 0 1
refdes=Dc3r3
}
C 52900 48600 1 0 0 spice-model-1.sym
{
T 53000 49300 5 10 0 1 0 0 1
device=model
T 53000 49200 5 10 1 1 0 0 1
refdes=A1
T 54200 48900 5 10 1 1 0 0 1
model-name=1n4148
T 53400 48700 5 10 1 1 0 0 1
file=1n4148.mod
}
N 41800 46200 50300 46200 4
C 46300 45000 1 0 0 on-off-switch-1.sym
{
T 45850 44800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 46700 45350 5 10 1 1 0 0 1
refdes=Xc2r2
}
C 48300 45000 1 0 0 on-off-switch-1.sym
{
T 47850 44800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 48700 45350 5 10 1 1 0 0 1
refdes=Xc3r2
}
C 48300 47000 1 0 0 on-off-switch-1.sym
{
T 47850 46800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 48700 47350 5 10 1 1 0 0 1
refdes=Xc3r1
}
C 46300 47000 1 0 0 on-off-switch-1.sym
{
T 45850 46800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 46700 47350 5 10 1 1 0 0 1
refdes=Xc2r1
}
C 44300 47000 1 0 0 on-off-switch-1.sym
{
T 43850 46800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 44700 47350 5 10 1 1 0 0 1
refdes=Xc1r1
}
C 44300 45000 1 0 0 on-off-switch-1.sym
{
T 43850 44800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 44700 45350 5 10 1 1 0 0 1
refdes=Xc1r2
}
C 44300 43000 1 0 0 on-off-switch-1.sym
{
T 43850 42800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 44700 43350 5 10 1 1 0 0 1
refdes=Xc1r3
}
C 46300 43000 1 0 0 on-off-switch-1.sym
{
T 45850 42800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 46700 43350 5 10 1 1 0 0 1
refdes=Xc2r3
}
C 48300 43000 1 0 0 on-off-switch-1.sym
{
T 47850 42800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 48700 43350 5 10 1 1 0 0 1
refdes=Xc3r3
}
C 51300 48700 1 90 0 io-pin-1.sym
{
T 51300 49400 5 10 0 1 90 0 1
model-name=pin
T 51200 48700 5 10 1 1 90 0 1
refdes=X4
}
C 50100 47100 1 270 0 diode-1.sym
{
T 50700 46700 5 10 0 0 270 0 1
device=DIODE
T 50100 47100 5 10 0 0 0 0 1
model-name=1N4148
T 50600 46800 5 10 1 1 270 0 1
refdes=Dc4r1
}
C 50100 45100 1 270 0 diode-1.sym
{
T 50700 44700 5 10 0 0 270 0 1
device=DIODE
T 50100 45100 5 10 0 0 0 0 1
model-name=1N4148
T 50600 44800 5 10 1 1 270 0 1
refdes=Dc4r2
}
N 51300 43100 51300 48700 4
C 50100 43100 1 270 0 diode-1.sym
{
T 50700 42700 5 10 0 0 270 0 1
device=DIODE
T 50100 43100 5 10 0 0 0 0 1
model-name=1N4148
T 50600 42800 5 10 1 1 270 0 1
refdes=Dc4r3
}
C 50300 45000 1 0 0 on-off-switch-1.sym
{
T 49850 44800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 50700 45350 5 10 1 1 0 0 1
refdes=Xc4r2
}
C 50300 47000 1 0 0 on-off-switch-1.sym
{
T 49850 46800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 50700 47350 5 10 1 1 0 0 1
refdes=Xc4r1
}
C 50300 43000 1 0 0 on-off-switch-1.sym
{
T 49850 42800 5 10 0 0 0 0 1
device=SWITCH_PUSHBUTTON_NC
T 50700 43350 5 10 1 1 0 0 1
refdes=Xc4r3
}