@echo off
:: Set lid close behaviour while plugged in (0 = Do Nothing)
powercfg /setACvalueIndex scheme_current sub_buttons lidAction 0

:: Set lid close behaviour on battery (1 = Sleep)
powercfg /setDCvalueIndex scheme_current sub_buttons lidAction 1

:: Adjust display sleep on battery (number = minutes)
powercfg /CHANGE monitor-timeout-dc 5

:: Adjust display sleep on battery (number = minutes)
powercfg /CHANGE monitor-timeout-ac 10

:: Adjust When computer goes to sleep on battery (number is minutes)
powercfg /CHANGE standby-timeout-dc 20


:: Adjust When computer goes to sleep while plugged in (number is minutes)
:: we default to zero so computer never goes to sleep while plugged in
powercfg /CHANGE standby-timeout-ac 0


:: Applys the updated power scheme
powercfg /SETACTIVE SCHEME_CURRENT

echo Power settings have been updated
pause
