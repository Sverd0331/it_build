@echo off

powercfg /setACvalueIndex scheme_current sub_buttons lidAction 0

powercfg /setDCvalueIndex scheme_current sub_buttons lidAction 1

powercfg /CHANGE monitor-timeout-dc 5

powercfg /CHANGE monitor-timeout-ac 10

powercfg /CHANGE standby-timeout-dc 20

powercfg /CHANGE standby-timeout-ac 0

powercfg /SETACTIVE SCHEME_CURRENT

echo Power settings have been updated
pause
