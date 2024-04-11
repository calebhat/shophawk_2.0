@echo off
set SECRET_KEY_BASE=PR0sWJL4C/5YD5vdh5Qu2mHVMaNRGCYZVTwIDVrN1ubHkCIWMminkcR1xEF8hza3
set MIX_ENV=prod
iex -S mix phx.server
cmd /K